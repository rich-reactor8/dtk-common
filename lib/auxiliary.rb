require 'etc'
module DTK
  module Common
    module AuxMixin
      def get_ssh_rsa_pub_key()
        path = "#{running_process_home_dir()}/.ssh/id_rsa.pub"
        begin
          File.open(path){|f|f.read}.chomp
         rescue Errno::ENOENT
          raise Error.new("user (#{ENV['USER']}) does not have a public key under #{path}")
         rescue => e
          raise e
         end
      end

      def hash_subset(hash,keys_subset)
        keys_subset.inject(Hash.new) do |h,k|
          hash.has_key?(k) ? h.merge(k => hash[k]) : h
        end
      end

      def convert_keys_to_symbols(hash)
        hash.keys.inject(Hash.new){|h,k|h.merge(k.to_sym => hash[k])}
      end

      def dtk_instance_repo_username()
        #on ec2 changing mac addresses; so selectively pick instance id on ec2
        unique_id = get_ec2_instance_id() || get_macaddress().gsub(/:/,'-')
        "dtk-#{unique_id}"
      end

      def update_ssh_known_hosts(remote_host)
        fingerprint = `ssh-keyscan -H -t rsa #{remote_host}`
        ssh_known_hosts = "#{running_process_home_dir()}/.ssh/known_hosts"
        if File.file?(ssh_known_hosts)
          `ssh-keygen -f "#{ssh_known_hosts}" -R #{remote_host}`
        end
        File.open(ssh_known_hosts,"a"){|f| f << "#{fingerprint}\n"}
      end

      def get_macaddress()
        return @macaddress if @macaddress
        #TODO: may just use underlying routines for facter - macaddress
        require 'facter'
        collection = ::Facter.collection
        @macaddress = collection.fact('macaddress').value
      end

      def get_ec2_public_dns()
        get_ec2_meta_data('public-hostname')
      end

      def get_ec2_instance_id()
        # @ec2_instance_id_cached used because it could have tried to get this info and result was null
        return @ec2_instance_id if @ec2_instance_id_cached
        @ec2_instance_id_cached = true
        @ec2_instance_id = get_ec2_meta_data('instance-id')
      end

      def snake_to_camel_case(camel_case)
        camel_case.gsub(/(^|_)(.)/) { $2.upcase }
      end

      def  running_process_user()
        Etc.getpwuid(Process.uid).name
      end
      def running_process_home_dir()
        Etc.getpwuid(Process.uid).dir
      end

     private
      def get_ec2_meta_data(var)
       #Fragments taken from Puppetlabs facter ec2
        require 'open-uri'
        require 'timeout'
        ret = nil
        begin 
          url = "http://169.254.169.254:80/"
          Timeout::timeout(WaitSec) {open(url)}
          ret = OpenURI.open_uri("http://169.254.169.254/2008-02-01/meta-data/#{var}").read
         rescue Timeout::Error
         rescue
          #TODO: unexpected; write t log what error is
        end
        ret
      end    
      WaitSec = 2
    end
    module Aux
      class << self
        include AuxMixin
      end
    end
  end
end