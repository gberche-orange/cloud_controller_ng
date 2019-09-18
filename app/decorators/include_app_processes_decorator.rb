module VCAP::CloudController
  class IncludeAppProcessesDecorator
    class << self
      def decorate(hash, apps)
        hash[:included] ||= {}
        process_guids = apps.map(&:process_guids).flatten.uniq
        processes = ProcessModel.where(guid: process_guids).order(:created_at)

        hash[:included][:processes] = processes.map { |process| Presenters::V3::ProcessPresenter.new(process).to_hash }
        hash
      end
    end
  end
end
