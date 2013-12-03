#
# Author:: Noah Kantrowitz <noah@coderanger.net>
#
# Copyright 2013, Balanced, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path('../jenkins', __FILE__)

class Chef
  class Resource::JenkinsConfig < Resource
    include Poise(Jenkins)
    actions(:enable, :disable)

    attribute(:source, kind_of: String)
    attribute(:cookbook, kind_of: [String, Symbol], default: lazy { cookbook_name })
    attribute(:content, kind_of: String)
    attribute(:options, option_collector: true)

    def path
      ::File.join(parent.config_d_path, "#{name}.xml")
    end

    def after_created
      super
      notifies(:rebuild_config, parent)
      raise "#{self}: One of source or content is required" unless source || content
      raise "#{self}: Only one of source or content can be specified" if source && content
    end
  end

  class Provider::JenkinsConfig < Provider
    include Poise

    def action_enable
      notifying_block do
        write_config
      end
    end

    def action_disable
      notifying_block do
        delete_config
      end
    end

    private

    def write_config
      if new_resource.source
        template new_resource.path do
          source new_resource.source
          cookbook new_resource.cookbook.to_s
          owner new_resource.parent.user
          group new_resource.parent.group
          variables new_resource.options.merge(new_resource: new_resource)
          mode '600'
        end
      else
        file new_resource.path do
          content new_resource.content
          owner new_resource.parent.user
          group new_resource.parent.group
          mode '600'
        end
      end
    end

    def delete_config
      file new_resource.path do
        action :delete
      end
    end
  end
end