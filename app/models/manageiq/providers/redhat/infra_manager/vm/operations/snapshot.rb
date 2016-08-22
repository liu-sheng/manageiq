module ManageIQ::Providers::Redhat::InfraManager::Vm::Operations::Snapshot
  def raw_create_snapshot(_name, desc, memory)
    with_snapshots_service(uid_ems) do |snapshots_service|
      snapshots_service.add(:description => desc, :persist_memorystate => memory)
    end
  end

  def raw_remove_snapshot(snapshot_id)
    snapshot = snapshots.find_by_id(snapshot_id)
    raise _("Requested VM snapshot not found, unable to remove snapshot") unless snapshot
    with_snapshots_service(uid_ems) do |snapshots_service|
      snapshots_service.snapshot_service(snapshot.uid_ems).remove
    end
  end

  def raw_revert_to_snapshot(snapshot_id)
    snapshot = snapshots.find_by_id(snapshot_id)
    raise _("Requested VM snapshot not found, unable to RevertTo snapshot") unless snapshot
    with_snapshots_service(uid_ems) do |snapshots_service|
      snapshots_service.snapshot_service(snapshot.uid_ems).restore
    end
  end

  def supports_snapshots?
    true
  end

  def snapshot_name_optional?
    true
  end

  def validate_remove_all_snapshots
    {:available => false, :message => "Removing all snapshots is currently not supported"}
  end

  private

  def with_snapshots_service(vm_uid_ems)
    closeable_service = closeable_snapshots_service(ext_management_system, vm_uid_ems)
    yield closeable_service
  ensure
    closeable_service.close if closeable_service
  end

  def closeable_snapshots_service(ems, vm_uid_ems, options = {})
    version = options[:version] || 4
    connection = ems.connect(:version => version)
    service = connection.system_service.vms_service.vm_service(vm_uid_ems).snapshots_service
    CloseableService.new(service) { connection.close }
  end

  class CloseableService < SimpleDelegator
    attr_reader :closing_block
    def initialize(service, &closing_block)
      @closing_block = closing_block
      super service
    end

    def close
      closing_block.call
    end
  end
end
