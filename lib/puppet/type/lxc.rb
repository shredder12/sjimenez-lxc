Puppet::Type.newtype(:lxc) do
  @doc = 'LXC management'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Name for the container.'
  end

  newparam(:template) do
    desc 'Template on which the container will be based.'
    defaultto 'ubuntu'
    newvalues(/\w+/)
  end

  newparam(:template_options) do
    desc 'Parameters to be passed down to the template.'
    validate do |value|
      unless value.kind_of?Array
        raise ArgumentError, "template_options is #{value.class}, expected Array"
      end
    end
  end

  newparam(:timeout) do
    desc 'Timeout in seconds for container operations.'
    defaultto 10
    newvalues(/\d+/)
  end

  newparam(:storage_backend) do
    desc 'Storage backend type for the container.'
    defaultto :dir
    newvalues(:dir, :lvm, :btrfs, :loop, :best)
  end

  newparam(:storage_options) do
    desc 'Options for the storage backend.'

    validate do |value|
      unless value.kind_of?Hash
        raise ArgumentError, "storage_options is #{value.class}, expected Hash"
      end

      if value['dir'] and value.size > 1
        raise ArgumentError, 'cannot use more storage_options than dir'
      elsif value['dir'].nil?
        value.keys.each do |k|
          raise ArgumentError, "#{k} is not a valid storage option" unless ['lvname', 'vgname', 'thinpool', 'fstype', 'fssize'].include?k
        end
      end

      if value['dir'] and @resource[:storage_backend] != :dir
        raise ArgumentError, 'storage_backend and storage_options do not match'
      end
    end
  end

  newparam(:config_options) do
    desc 'Custom options for container'

    validate do |value|
      unless value.kind_of?Hash
        raise ArgumentError, "config_options is #{value.class}, expected Hash"
      end
    end
  end

  newproperty(:state) do
    desc 'Whether a container should be running, stopped or frozen.'

    defaultto :running

    newvalue(:running, :event => :container_started) do
      provider.start
    end

    newvalue(:stopped, :event => :container_stopped) do
      provider.stop
    end

    newvalue(:frozen, :event => :container_frozen) do
      provider.freeze
    end

    def retrieve
      provider.status
    end
  end

  newproperty(:autostart) do
    desc 'Enable auto starting the container at boot time'
    defaultto false
    newvalues(:true,:false)
  end

  newproperty(:autostart_delay) do
    desc 'How long to wait (in seconds) after the container is started before starting the next one'
    newvalues(/^[1-9]+$/)
  end

  newproperty(:autostart_order) do
    desc 'An integer used to sort the containers when auto-starting a series of containers at once'
    newvalues(/^[1-9]+$/)
  end

  newproperty(:groups) do
    desc 'A multi-value key (can be used multiple times) to put the container in a container group'
    validate do |value|
      unless value.kind_of?Array
        raise ArgumentError, "groups is #{value.class}, expected Array"
      end
    end
  end

  autorequire(:package) do
    ['lxc-bindings']
  end
end
