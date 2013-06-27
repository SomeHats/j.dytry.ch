require 'rubygems'
require 'yuicompressor'
require 'stylus'
require 'less'
require 'sass'
require 'closure-compiler'
require 'coffee-script'
require 'optipng'
require 'jpegtran'

module Jekyll
  module CompileCompress

    class CompileCompressFile < Jekyll::StaticFile

      # Generic convert/compress thingy
      # +dest+ is the String path to the destination dir
      #
      # Returns false if the file was not modified since last time (no-op).
      def write(dest)
        dest_path = File.join(dest, @dir, @name)

        type = File.extname(@name)

        # Fix problem of vanishing images
        #if ! [".png", ".jpg", ".jpeg"].include? type
        #  return false if File.exist? dest and !modified?
        #end
        @@mtimes[path] = mtime

        FileUtils.mkdir_p(File.dirname(dest_path))
        begin
          content = File.read(path)
          case type
            when ".css"
              # Compress CSS
              content = compressCss(content)

            when ".styl"
              # Convert Stylus to css
              begin
                print "Converting #{@name} to css... "
                Stylus.use :nib
                content = Stylus.compile(content)
                print "done.\n"
              rescue => e
                puts "error.\nStylus: #{e.message}"
              else
                # compress & rename
                content = compressCss(content)
                dest_path = dest_path.gsub(/\.styl$/, ".css")
              end

            when ".less"
              # Convert less to css
              begin
                print "Converting #{@name} to css... "
                content = ::Less::Parser.new({:paths => [File.dirname(path)]}).parse(content).to_css
                print "done.\n"
              rescue => e
                puts "error.\nLess: #{e.message}"
              else
                # compress & rename
                content = compressCss(content)
                dest_path = dest_path.gsub(/\.less$/, ".css")
              end

            when ".sass"
              # Convert sass to css
              begin
                print "Converting #{@name} to css... "
                content = ::Sass::Engine.new(content, :syntax => :sass, :load_paths => [File.dirname(path)]).render
                print "done.\n"
              rescue => e
                puts "error.\nSass: #{e.message}"
              else
                # compress & rename
                content = compressCss(content)
                dest_path = dest_path.gsub(/\.sass$/, ".css")
              end

            when ".scss"
              # Convert scss to css
              begin
                print "Converting #{@name} to css... "
                content = ::Sass::Engine.new(content, :syntax => :scss, :load_paths => [File.dirname(path)]).render
                print "done.\n"
              rescue => e
                puts "error.\nSass: #{e.message}"
              else
                # compress & rename
                content = compressCss(content)
                dest_path = dest_path.gsub(/\.scss$/, ".css")
              end

            when ".js"
              # Compress JS
              content = compressJs(content)

            when ".coffee"
              # Convert coffeescript to javascript
              begin
                print "Converting #{@name} to js... "
                content = CoffeeScript.compile content
                print "done.\n"
              rescue => e
                puts "error.\nCoffee: #{e.message}"
              else
                # compress & rename
                content = compressJs(content)
                dest_path = dest_path.gsub(/\.coffee$/, ".js")
              end
          end

          File.open(dest_path, 'w') do |f|
            f.write(content)
          end

          # Images have to be optimised after they've been written
          case type
            when '.png'
              # If the name has an @2x, make a resized copy too.
              if @name.match(/@2[xX]/)
                small = halfImg dest_path, dest
                small_path = File.join(dest, @dir, small)
                print "Optimising #{small_path}... "
                result = Optipng.optimize([small_path], { :level => 2}).succeed
                #print "#{result.shift()[1] * -1}% reduction.\n"
              end
              print "Optimising #{@name}... "
              result = Optipng.optimize([dest_path], { :level => 2}).succeed
              #print "#{result.shift()[1] * -1}% reduction.\n"

            when '.jpg', '.jpeg'
              # If the name has an @2x, make a resized copy too.
              if @name.match(/@2[xX]/)
                small = halfImg dest_path, dest
                small_path = File.join(dest, @dir, small)
                print "Optimising #{@small}... "
                reduction = IO.popen("du #{small_path}").readlines.first.to_f
                Jpegtran.optimize(small_path, { :progressive => true, :optimise => true })
                reduction = IO.popen("du #{small_path}").readlines.first.to_f / reduction
                print "#{(100 - reduction * 100).to_s[0,5]}% reduction.\n"
              end
              print "Optimising #{@name}... "
              reduction = IO.popen("du #{dest_path}").readlines.first.to_f
              Jpegtran.optimize(dest_path, { :progressive => true, :optimise => true })
              reduction = IO.popen("du #{dest_path}").readlines.first.to_f / reduction
              print "#{(100 - reduction * 100).to_s[0,5]}% reduction.\n"
          end

        end

        true
      end

      def compressCss(content)
        if @site.config["compress"]
          print "Compressing #{@name}... "
          size = content.bytesize.to_f
          content = YUICompressor.compress_css(content)
          size = content.bytesize.to_f / size;
          print "#{(100 - size * 100).to_s[0,5]}% reduction.\n"
        end
        content
      end

      def compressJs(content)
        if @site.config["compress"]
          print "Compressing #{@name}... "
          size = content.bytesize.to_f
          content = Closure::Compiler.new.compile(content)
          size = content.bytesize.to_f / size;
          print "#{(100 - size * 100).to_s[0,5]}% reduction.\n"
        end
        content
      end

      def halfImg(dest_path, dest)
        print "Resizing #{@name}... "
        small_name = @name.gsub(/@2[xX]/, "")
        out = File.join(dest, @dir, small_name)
        IO.popen("convert #{dest_path} -resize 50% #{out}").readlines
        print "Saved as #{small_name}\n"
        small_name
      end

    end

    class CompCompGenerator < Jekyll::Generator
      safe true

      # Jekyll will have already added the *.js files as Jekyll::StaticFile
      # objects to the static_files array. We can replace them with our
      # CompileCompressFile objects to hijack what gets written, and where to.
      def generate(site)
        use = [".css", ".styl", ".less", ".sass", ".scss", ".js", ".coffee",
          ".png", ".jpg", ".jpeg"]

        site.static_files.clone.each do |sf|
          type = File.extname(sf.path)

          if use.include? type
            site.static_files.delete(sf)
            name = File.basename(sf.path);
            dest = File.dirname(sf.path).sub(site.source, '')
            site.static_files << CompileCompressFile.new(site, site.source, dest, name)
          end
        end
      end
    end

  end
end