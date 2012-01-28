#Auto generate the database schema

A plugin exists to autogenerate the database schema, in order to vizualize it in a pdf file: **superdumper**

You can find the plugin at this address [http://momo.brauchtman.net/2009/02/rails-plugin-superdumper-helps-you-visualize-your-database-schema/](http://momo.brauchtman.net/2009/02/rails-plugin-superdumper-helps-you-visualize-your-database-schema/)

This is how you would install the plugin (You will need to have a git client installed in order for this to work):

    bundle exec script/plugin install git://github.com/moritzh/superdumper.git

[You will also need a copy of GraphViz to generate the schema PDF](http://www.graphviz.org/Download..php)

You can launch the autogeneration by typing

    bundle exec rake db:superdumper

If you want to generate the dot file *and* the pdf file, edit

    /vendor/plugins/superdumper/tasks/superdumper_tasks.rake

and comment out the following line

    File.delete("#{RAILS_ROOT}/database.dot")

It will then generate both, the dot file and the pdf file.
