module DtkCommon
  class GitRepo::Adapter::Rugged
    class Tree < Obj
      def initialize(repo_branch,rugged_tree)
        super(repo_branch)
        @rugged_tree = rugged_tree
      end

      def get_file_content(path)
        if blob = get_blob(path)
          blob.content
        end
      end

      def list_files()
        ret = Array.new
        @rugged_tree.walk_blobs do |root,entry|
          ret << "#{root}#{entry[:name]}"
        end
        ret
      end

     private
      def get_blob(path)
        ret = nil
        dir = ""; file_part = path
        if path =~ /(.+\/)([^\/]+$)/
          dir = $1; file_part = $2
        end
        @rugged_tree.walk_blobs do |root,entry|
          if root == dir and entry[:name] == file_part
            return Blob.new(@repo_branch,entry)
          end
        end
        ret
      end

    end
  end
end
