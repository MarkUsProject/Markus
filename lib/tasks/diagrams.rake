namespace :doc do
  namespace :diagram do
    desc "Generate database schema diagram from Rails model classes."
    task :models do
      # To use it, two external programs, "railroad" and "graphviz", are needed. 
      # To install railroad use: "gem install railroad". 
      # To install "graphviz" use: aptitude install graphviz or yum install graphviz.

      puts "Generating the models diagram..."
      puts ""
      # Get the current time used in file name
      time = Time.new.utc
      base_dir = Dir.getwd
      doc_dir = File.join(base_dir, "doc")   
      unless File.exists? doc_dir 
        File.makedirs doc_dir
      end
      # the temporary .dot file, which will be deleted
      tmp_file_name = "temp#{time}".gsub(" ", "_") + ".dot"
      tmp_file = File.join doc_dir, tmp_file_name
      # the final .png file
      diagram_file_name = "models_#{time}".gsub(" ","_") + ".png"
      diagram_file = File.join doc_dir, diagram_file_name
      
      # generate a temporary .dot file which will be processed by dot
      # to get a .png file
      puts "Creating  #{tmp_file}..."
      if system "railroad -i -l -a -m -o #{tmp_file} -M > /dev/null 2>&1"
        puts "Successfully created: #{tmp_file}."
      else
        abort("Could not create .dot file - are you sure Railroad is installed?")
      end
      # process the .dot file to generate a .png file
      puts "Creating  #{diagram_file}..."
      if system "dot -Tpng #{tmp_file} > #{File.join doc_dir, diagram_file_name}"
        puts "Successfully created: #{diagram_file}."
      else
        abort("Could not create .png file - are you sure Graphviz is installed?")
      end
      puts "Deleting #{tmp_file}..."
      File.delete tmp_file
      puts "Successfully deleted: #{tmp_file}."
      
      puts ""
      puts "1 file generated: #{diagram_file}."
      puts ""
      
    end
  end
  
end
