require 'fileutils'
require 'combine_pdf'
require 'prawn'
require 'prawn/qrcode'
require 'zxing'
require 'rmagick'

class ExamTemplate < ActiveRecord::Base
  belongs_to :assignment
  validates :assignment, :filename, :num_pages, presence: true
  validates :num_pages, numericality: { greater_than_or_equal_to: 0,
                                        only_integer: true }

  has_many :template_divisions, dependent: :destroy

  # Create an ExamTemplate with the correct file
  def self.create_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment_name = Assignment.find(attributes[:assignment_id]).short_identifier
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name
    )
    FileUtils.mkdir template_path unless Dir.exists? template_path

    File.open(File.join(template_path, attributes[:filename]), 'wb') do |f|
      f.write blob
    end

    pdf = CombinePDF.parse blob
    attributes[:num_pages] = pdf.pages.length

    create(attributes)
  end

  # Instantiate an ExamTemplate with the correct file
  def self.new_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment = Assignment.find(attributes[:assignment_id])
    assignment_name = assignment.short_identifier
    filename = attributes[:filename]
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name
    )
    FileUtils.mkdir template_path unless Dir.exists? template_path
    File.open(File.join(template_path, filename), 'wb') do |f|
      f.write blob
    end
    pdf = CombinePDF.parse blob
    num_pages = pdf.pages.length
    new_template = ExamTemplate.new(
      filename: filename,
      num_pages: num_pages,
      assignment: assignment
    )
    return new_template
  end

  # Replace an ExamTemplate with the correct file
  def replace_with_file(blob, attributes={})
    return unless attributes.has_key? :assignment_id
    assignment_name = Assignment.find(attributes[:assignment_id]).short_identifier
    template_path = File.join(
      MarkusConfigurator.markus_exam_template_dir,
      assignment_name
    )

    File.open(File.join(template_path, attributes[:filename]), 'wb') do |f|
      f.write blob
    end

    pdf = CombinePDF.parse blob
    self.update(num_pages: pdf.pages.length)
  end

  # Generate copies of the given exam template, with the given start number.
  def generate_copies(num_copies, start=1)
    template_path = File.join(
      base_path,
      filename
    )
    template_pdf = CombinePDF.load template_path
    generated_pdf = CombinePDF.new
    (start..start + num_copies - 1).each do |exam_num|
      pdf = Prawn::Document.new(margin: 20)
      num_pages.times do |page_num|
        qrcode_content = "#{assignment.short_identifier}-#{exam_num}-#{page_num + 1}"
        qrcode = RQRCode::QRCode.new qrcode_content, level: :l, size: 2
        alignment = page_num % 2 == 0 ? :right : :left
        pdf.render_qr_code(qrcode, align: alignment, dot: 3.2, stroke: false)
        pdf.text("Exam #{exam_num}-#{page_num + 1}", align: alignment)
        pdf.start_new_page
      end
      combine_pdf_qr = CombinePDF.parse(pdf.render)
      template_pdf.pages.zip(combine_pdf_qr.pages) do |template_page, qr_page|
        generated_pdf << (qr_page << template_page)
      end
    end

    generated_pdf.save File.join(
      base_path,
      "#{start}-#{start + num_copies - 1}.pdf"
    )
  end

  # Split up PDF file based on this exam template.
  def split_pdf(path)
    # Create directory for files whose QR code couldn't be parsed
    error_dir = File.join(base_path, 'error')
    raw_dir = File.join(base_path, 'raw')
    FileUtils.mkdir error_dir unless Dir.exists? error_dir
    FileUtils.mkdir raw_dir unless Dir.exists? raw_dir

    basename = File.basename path, '.pdf'
    pdf = CombinePDF.load path
    partial_exams = Hash.new do |hash, key|
      hash[key] = []
    end
    pdf.pages.each_index do |i|
      page = pdf.pages[i]
      new_page = CombinePDF.new
      new_page << page
      new_page.save File.join(raw_dir, "#{basename}-#{i}.pdf")

      # Snip out the part of the PDF that contains the QR code.
      img = Magick::Image::read(File.join(raw_dir, "#{basename}-#{i}.pdf")).first
      qr_img = img.crop 0, 10, img.columns, img.rows / 5
      qr_img.write File.join(raw_dir, "#{basename}-#{i}.png")

      # qrcode_string = ZXing.decode new_page.to_pdf
      qrcode_string = ZXing.decode qr_img.to_blob
      qrcode_regex = /(?<short_id>\w+)-(?<exam_num>\d+)-(?<page_num>\d+)/
      m = qrcode_regex.match qrcode_string
      if m.nil?
        new_page.save File.join(error_dir, "#{basename}-#{i}.pdf")
      else
        partial_exams[m[:exam_num]] << [m[:page_num].to_i, page]
        puts "#{m[:short_id]}: exam number #{m[:exam_num]}, page #{m[:page_num]}"
      end
    end

    save_pages partial_exams
  end

  private

  # Save the pages into groups for this assignment
  def save_pages(partial_exams)
    complete_dir = File.join(base_path, 'complete')
    incomplete_dir = File.join(base_path, 'incomplete')

    partial_exams.each do |exam_num, pages|
      next if pages.empty?
      pages.sort_by! { |page_num, _| page_num }

      # Save raw pages
      if pages.length == num_pages
        destination = File.join complete_dir, "#{exam_num}"
      else
        destination = File.join incomplete_dir, "#{exam_num}"
      end
      FileUtils.mkdir_p destination unless Dir.exists? destination
      pages.each do |page_num, page|
        new_pdf = CombinePDF.new
        new_pdf << page
        new_pdf.save File.join(destination, "#{page_num}.pdf")
      end

      group = Group.find_or_create_by(
        group_name: group_name_for(exam_num),
        repo_name: group_name_for(exam_num)
      )

      Grouping.create(
        group: group,
        assignment: assignment
      )

      group.access_repo do |repo|
        assignment_folder = assignment.repository_folder
        txn = repo.get_transaction(Admin.first.user_name)


        # Pages that belong to a division
        template_divisions.each do |division|
          new_pdf = CombinePDF.new
          pages.each do |page_num, page|
            if division.start <= page_num && page_num <= division.end
              new_pdf << page
            end
          end
          txn.add(File.join(assignment_folder,
                            "#{division.label}.pdf"),
                  new_pdf.to_pdf,
                  'application/pdf'
          )
        end

        # Pages that don't belong to any division
        extra_pages = pages.reject do |page_num, _|
          template_divisions.any? do |division|
            division.start <= page_num && page_num <= division.end
          end
        end
        extra_pdf = CombinePDF.new
        extra_pdf << extra_pages.collect { |_, page| page }
        txn.add(File.join(assignment_folder,
                          "EXTRA.pdf"),
                extra_pdf.to_pdf,
                'application/pdf'
        )
        repo.commit(txn)
      end
    end
  end

  def base_path
    File.join MarkusConfigurator.markus_exam_template_dir,
              assignment.short_identifier
  end

  def group_name_for(exam_num)
    "#{assignment.short_identifier}_paper_#{exam_num}"
  end
end
