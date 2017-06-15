require 'optparse'

module CfnDsl
  # Runner class to handle commandline invocation
  class Runner
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def self.invoke!
      options = {}

      optparse = OptionParser.new do |opts|
        opts.version = CfnDsl::VERSION
        opts.banner = 'Usage: cfndsl [options] FILE'

        # Define the options, and what they do
        options[:output] = '-'
        opts.on('-o', '--output FILE', 'Write output to file') do |file|
          options[:output] = file
        end

        options[:extras] = []
        opts.on('-y', '--yaml FILE', 'Import yaml file as local variables') do |file|
          options[:extras].push([:yaml, File.expand_path(file)])
        end

        opts.on('-r', '--ruby FILE', 'Evaluate ruby file before template') do |file|
          options[:extras].push([:ruby, File.expand_path(file)])
        end

        opts.on('-j', '--json FILE', 'Import json file as local variables') do |file|
          options[:extras].push([:json, File.expand_path(file)])
        end

        opts.on('-p', '--pretty', 'Pretty-format output JSON') do
          options[:pretty] = true
        end

        opts.on('-f', '--format FORMAT', 'Specify the output format (JSON default)') do |format|
          raise "Format #{format} not supported" unless format == 'json' || format == 'yaml'
          options[:outformat] = format
        end

        opts.on('-D', '--define "VARIABLE=VALUE"', 'Directly set local VARIABLE as VALUE') do |file|
          options[:extras].push([:raw, file])
        end

        options[:verbose] = false
        opts.on('-v', '--verbose', 'Turn on verbose ouptut') do
          options[:verbose] = true
        end

        # This displays the help screen, all programs are
        # assumed to have this option.
        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end
      end

      optparse.parse!
      unless ARGV[0]
        puts optparse.help
        exit(1)
      end

      filename = File.expand_path(ARGV[0])
      verbose = options[:verbose] && STDERR

      model = CfnDsl.eval_file_with_extras(filename, options[:extras], verbose)

      output = STDOUT
      if options[:output] != '-'
        verbose.puts("Writing to #{options[:output]}") if verbose
        output = File.open(File.expand_path(options[:output]), 'w')
      elsif verbose
        verbose.puts('Writing to STDOUT')
      end

      if options[:outformat] == 'yaml'
        data = model.to_json
        output.puts JSON.parse(data).to_yaml
      else
        output.puts options[:pretty] ? JSON.pretty_generate(model) : model.to_json
      end
    end
  end
end
