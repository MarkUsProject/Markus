require 'set'

# Helpers for handling uploading data files for various models.
module UploadHelper
  # max yaml text size in bytes.
  YAML_MAX_BYTES = 2_000_000
  # max estimated size after alias expansion.
  YAML_MAX_EXPANDED_NODES = 200_000

  def process_file_upload(allowed_filetypes = %w[.csv .yml])
    encoding = params[:encoding] || 'UTF-8'
    upload_file = params.require(:upload_file)

    if upload_file.size == 0
      raise StandardError, I18n.t('upload_errors.blank')
    end

    if allowed_filetypes.size == 1
      filetype = allowed_filetypes[0]
    else
      filetype = File.extname(upload_file.original_filename)
    end

    if filetype == '.csv'
      {
        type: '.csv',
        contents: upload_file.read.encode(Encoding::UTF_8, encoding),
        encoding: encoding
      }
    elsif %w[.yml .yaml].include? filetype
      {
        type: '.yml',
        contents: parse_yaml_content(upload_file.read.encode(Encoding::UTF_8, encoding))
      }
    else
      raise StandardError, I18n.t('upload_errors.malformed_csv')
    end
  end

  # Unzip the file at +zip_file_path+ and yield the name of each directory and an
  # UploadedFile object for each file.
  def upload_files_helper(new_folders, new_files, unzip: false,
                          max_file_size: nil,
                          max_zip_entries: Settings.max_zip_file_entries,
                          max_zip_total_size: Settings.max_zip_total_size,
                          &block)
    new_folders.each(&block)
    new_files.each do |f|
      if unzip && File.extname(f.path).casecmp?('.zip')
        Zip::File.open(f.path) do |zipfile|
          total_size = 0
          if max_zip_entries && zipfile.size > max_zip_entries
            raise StandardError, I18n.t('upload_errors.too_many_zip_entries', max: max_zip_entries)
          end
          zipfile.each do |zf|
            if zf.directory?
              yield zf.name
              next
            end

            entry_size = zf.size
            if entry_size && max_file_size && entry_size > max_file_size
              max_mb = (max_file_size / 1_000_000.0).round(2)
              raise StandardError, I18n.t('upload_errors.zip_entry_too_large',
                                          file_name: zf.name, max_size: max_mb)
            end
            if entry_size && max_zip_total_size
              total_size += entry_size
              if total_size > max_zip_total_size
                max_mb = (max_zip_total_size / 1_000_000.0).round(2)
                raise StandardError, I18n.t('upload_errors.zip_too_large_total', max_mb: max_mb)
              end
            end

            next unless zf.file?

            mime = Rack::Mime.mime_type(File.extname(zf.name))
            tempfile = Tempfile.new.binmode
            streamed_size = 0

            begin
              zf.get_input_stream do |io|
                while (chunk = io.read(64 * 1024))
                  streamed_size += chunk.bytesize
                  if max_file_size && streamed_size > max_file_size
                    max_mb = (max_file_size / 1_000_000.0).round(2)
                    raise StandardError, I18n.t('upload_errors.zip_entry_too_large',
                                                file_name: zf.name, max_size: max_mb)
                  end
                  if entry_size.nil? && max_zip_total_size && total_size + streamed_size > max_zip_total_size
                    max_mb = (max_zip_total_size / 1_000_000.0).round(2)
                    raise StandardError, I18n.t('upload_errors.zip_too_large_total', max_mb: max_mb)
                  end
                  tempfile.write(chunk)
                end
              end
            rescue StandardError
              tempfile.close!
              raise
            end

            entry_total = entry_size || streamed_size
            total_size += entry_total if entry_size.nil? && max_zip_total_size

            tempfile.rewind
            yield ActionDispatch::Http::UploadedFile.new(filename: zf.name, tempfile: tempfile, type: mime)
          end
        end
      else
        yield f
      end
    end
  end

  # Parse the +yaml_string+ and return the data as a hash.
  def parse_yaml_content(yaml_string)
    validate_yaml_alias_safety!(yaml_string)

    YAML.safe_load(yaml_string,
                   permitted_classes: [
                     Date, Time, Symbol, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone,
                     ActiveSupport::Duration, ActiveSupport::HashWithIndifferentAccess
                   ],
                   aliases: true)
  end

  # keep normal aliases, but block alias bombs.
  def validate_yaml_alias_safety!(yaml_string)
    # Block very large yaml text before parsing.
    raise_yaml_complexity_error! if yaml_string.bytesize > YAML_MAX_BYTES

    # parse yaml into an ast so we can inspect structure safely.
    yaml_ast = Psych.parse_stream(yaml_string)
    anchors = scan_yaml_ast(yaml_ast)

    raise_yaml_complexity_error! if verify_expanded_size!(yaml_ast, anchors) > YAML_MAX_EXPANDED_NODES
  end

  def scan_yaml_ast(yaml_ast)
    # count shape info while walking nodes.
    num_nodes = 0
    anchors = {}
    stack = [yaml_ast]

    until stack.empty?
      node = stack.pop
      next if node.nil?

      num_nodes += 1
      # stop if ast is too large.
      raise_yaml_complexity_error! if num_nodes > YAML_MAX_EXPANDED_NODES

      if node.respond_to?(:anchor) && !node.anchor.nil? && !node.is_a?(Psych::Nodes::Alias)
        # duplicate anchor names are not allowed.
        raise_yaml_complexity_error! if anchors.key?(node.anchor)
        anchors[node.anchor] = node
      end

      yaml_node_children(node).each { |child| stack << child }
    end

    anchors
  end

  def verify_expanded_size!(node, anchors, cache: nil, visiting: nil, total: nil)
    return 0 if node.nil?

    total = 0 if total.nil?
    cache = {}.compare_by_identity if cache.nil?
    visiting = Set.new.compare_by_identity if visiting.nil?

    # Raise an error if cyclic alias reference is detected
    raise_yaml_complexity_error! if visiting.include?(node)

    return total + cache[node] if cache.key?(node)

    visiting.add(node)
    total += 1

    if node.is_a?(Psych::Nodes::Alias)
      # Follow alias to its target anchor. Raise an error if the anchor is not found.
      target = anchors[node.anchor]
      raise_yaml_complexity_error! if target.nil?
      total = verify_expanded_size!(target, anchors, cache: cache, visiting: visiting, total: total)
    else
      yaml_node_children(node).each do |child|
        total = verify_expanded_size!(child, anchors, cache: cache, visiting: visiting, total: total)
        raise_yaml_complexity_error! if total > YAML_MAX_EXPANDED_NODES
      end
    end

    visiting.delete(node)
    cache[node] = total
    total = [total, YAML_MAX_EXPANDED_NODES + 1].min
    raise_yaml_complexity_error! if total > YAML_MAX_EXPANDED_NODES
    total
  end

  def yaml_node_children(node)
    case node
    when Psych::Nodes::Stream, Psych::Nodes::Document, Psych::Nodes::Mapping, Psych::Nodes::Sequence
      node.children
    else
      []
    end
  end

  def raise_yaml_complexity_error!
    # use one clear user-facing error message.
    raise StandardError, I18n.t('upload_errors.too_complex_yaml')
  end
end
