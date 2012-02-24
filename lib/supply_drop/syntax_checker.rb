module SupplyDrop
  class SyntaxChecker
    def initialize(path)
      @path = path
    end

    def validate_puppet_files
      Dir.glob("#{@path}/**/*.pp").map do |puppet_file|
        output = `puppet parser validate #{puppet_file}`
        $?.to_i == 0 ? nil : [puppet_file, output]
      end.compact
    end

    def validate_templates
      Dir.glob("#{@path}/**/*.erb").map do |template_file|
        output = `erb -x -T '-' #{template_file} | ruby -c 2>&1`
        $?.to_i == 0 ? nil : [template_file, output]
      end.compact
    end
  end
end
