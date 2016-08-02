class ContainerDefinition < ApplicationRecord
  # :name, :image, :image_pull_policy, :memory, :cpu
  belongs_to :container_group
  belongs_to :ext_management_system, :foreign_key => :ems_id
  has_many :container_port_configs, :dependent => :destroy
  has_many :container_env_vars,     :dependent => :destroy
  has_one :container,               :dependent => :destroy
  has_one :security_context,        :as => :resource, :dependent => :destroy
  has_and_belongs_to_many           :container_images, :join_table => :containers

  def disconnect_inv
    _log.info "Disconnecting Container definition [#{name}] id [#{id}]"
    self.container.try(:disconnect_inv)
    self.deleted_on = Time.now.utc
    self.container_group = nil
    self.old_ems_id = self.ems_id
    self.ems_id = nil
    save
  end
end
