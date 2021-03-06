module DtkCommon
  module DSL
    class DirectoryParser
      require File.expand_path("directory_parser/linux",File.dirname(__FILE__))
      require File.expand_path("directory_parser/git",File.dirname(__FILE__))

      def initialize(directory_type)
        unless @file_info = file_info(directory_type)
          raise Error.new("Illegal directory type (#{directory_type})")
        end
        @directory_type = directory_type
      end

      DirectoryParserMethods = [:parse_directory]
      def self.implements_method?(method_name)
        DirectoryParserMethods.include?(method_name)
      end

      def file_content(rel_file_path)
        get_content(rel_file_path)
      end

      #if file_type is given returns DtkCommon::DSL::FileParser::OutputArray
      #otherwise returns hash at top level taht is indexed by file types found
      def parse_directory(file_type=nil,opts={})
        pruned_file_info =
          if file_type
            matches = @file_info.select{|r|r[:file_type] == file_type}
            if matches.empty?
              raise Error.new("Illegal file type (#{file_type}) for directory_type (#{directory_type})")
            end
            matches
          else
            @file_info
          end
        #instantiate any rel_path_pattern
        pruned_file_instances  = instantiate_rel_path_patterns(pruned_file_info)
        ret = Hash.new
        pruned_file_instances.each do |r|
          file_content = get_content(r[:rel_path])
          opts[:file_path] = r[:rel_path]
          new_parsed = FileParser.parse_content(r[:file_type],file_content,opts)
          ret[file_type] = (ret[file_type] ? ret[file_type] + new_parsed : new_parsed)
        end
        file_type.nil? ? ret : ret[file_type]
      end

      def self.default_rel_path?(directory_type,file_type)
        if match = file_info_single_match?(directory_type,file_type)
          match[:default_rel_path]
        end
      end
     private
      def self.file_info_single_match?(directory_type,file_type)
        matches = file_info(directory_type).select{|r|r[:file_type] == file_type}
        if matches.empty? then nil
        elsif matches.size == 1 then matches.first
        else
          raise Error.new("Unexpected to get multiple matches")
        end
      end
      def self.file_info(directory_type)
        DirectoryTypeFiles[directory_type]
      end

      def file_info(directory_type)
        self.class.file_info(directory_type)
      end

      def instantiate_rel_path_patterns(rel_file_info)
        ret = Array.new
        all_files_from_root = nil
        rel_file_info.each do |r|
          if rel_path = r[:rel_path]
            ret << r
          else
            all_files_from_root ||= all_files_from_root()
            ret += find_rel_path_matches(r,all_files_from_root)
          end
        end
        ret
      end

      def find_rel_path_matches(r,all_files_from_root)
        ret = Array.new
        unless r[:rel_path_pattern]
          return ret
        end

        rel_path_pattern = r[:rel_path_pattern]
        rel_path_patterns = (rel_path_pattern.kind_of?(Array) ? rel_path_pattern : [rel_path_pattern])
        rel_path_patterns.each do |pat|
          all_files_from_root.each do |f|
            if f =~ pat
              file_key = $1
              ret << {:rel_path => f, :file_type => r[:file_type], :key => file_key}
            end
          end
          return ret unless ret.empty?
        end
        ret
      end
      DirectoryTypeFiles = {
        :service_module =>
        [
         {
           :file_type => :component_module_refs,
           :rel_path_pattern => [/(^module_refs.yaml$)/,/(^global_module_refs.json$)/],
           :default_rel_path => 'module_refs.yaml',
         },
         {
           :file_type => :assembly,
           :rel_path_pattern => /^assemblies\/([^\/]+)\/assembly\.yaml$/
         }
        ],
        :component_module =>
        [
         {
           :file_type => :component_module_refs,
           :rel_path_pattern => [/(^module_refs.yaml$)/,/(^global_module_refs.json$)/],
           :default_rel_path => 'module_refs.yaml',
         }
        ],
        :test_module =>
        [
         {
           :file_type => :component_module_refs,
           :rel_path_pattern => [/(^module_refs.yaml$)/,/(^global_module_refs.json$)/],
           :default_rel_path => 'module_refs.yaml',
         }
        ]
      }
    end
  end
end
