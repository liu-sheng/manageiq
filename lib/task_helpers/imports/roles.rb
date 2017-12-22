module TaskHelpers
  class Imports
    class Roles
      def import(options = {})
        return unless options[:source]

        glob = File.file?(options[:source]) ? options[:source] : "#{options[:source]}/*.yaml"
        Dir.glob(glob) do |fname|
          begin
            roles = YAML.load_file(fname)
            import_roles(roles)
          rescue => e
            $stderr.puts "Error importing #{fname} : #{e.message}"
          end
        end
      end

      private

      def import_roles(roles)
        roles.each do |r|
          r['miq_product_feature_ids'] = MiqProductFeature.all.collect do |f|
            f.id if r['feature_identifiers'] && r['feature_identifiers'].include?(f.identifier)
          end.compact
          role = MiqUserRole.find_or_create_by(:name => r['name'])
          role.update_attributes!(r.reject { |k| k == 'feature_identifiers' })
        end
      end
    end
  end
end
