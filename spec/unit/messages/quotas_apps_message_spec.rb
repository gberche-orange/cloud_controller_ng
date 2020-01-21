require 'spec_helper'
require 'messages/quotas_apps_message'

module VCAP::CloudController
  RSpec.describe QuotasAppsMessage do
    subject { QuotasAppsMessage.new(params) }

    describe 'apps' do
      context 'invalid keys are passed in' do
        let(:params) do
          { bad_key: 'bob' }
        end

        it 'is not valid' do
          expect(subject).to be_invalid
          expect(subject.errors.full_messages[0]).to include("Unknown field(s): 'bad_key'")
        end
      end

      describe 'total_memory_in_mb' do
        context 'when the type is a string' do
          let(:params) do
            { total_memory_in_mb: 'bob' }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Total memory in mb is not a number')
          end
        end

        context 'when the type is decimal' do
          let(:params) do
            { total_memory_in_mb: 1.1 }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Total memory in mb must be an integer')
          end
        end

        context 'when the type is a negative integer' do
          let(:params) do
            { total_memory_in_mb: -1 }
          end

          it 'is not valid because "unlimited" is set with null, not -1, in V3' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Total memory in mb must be greater than or equal to 0')
          end
        end

        context 'when the type is zero' do
          let(:params) do
            { total_memory_in_mb: 0 }
          end

          it { is_expected.to be_valid }
        end
        context 'when the type is nil (unlimited)' do
          let(:params) do
            { total_memory_in_mb: nil }
          end

          it { is_expected.to be_valid }
        end
      end

      describe 'per_process_memory_in_mb' do
        context 'when the type is a string' do
          let(:params) do
            { per_process_memory_in_mb: 'bob' }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Per process memory in mb is not a number')
          end
        end
        context 'when the type is decimal' do
          let(:params) do
            { per_process_memory_in_mb: 1.1 }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Per process memory in mb must be an integer')
          end
        end
        context 'when the type is a negative integer' do
          let(:params) do
            { per_process_memory_in_mb: -1 }
          end

          it 'is not valid because "unlimited" is set with null, not -1, in V3' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Per process memory in mb must be greater than or equal to 0')
          end
        end

        context 'when the type is zero' do
          let(:params) do
            { per_process_memory_in_mb: 0 }
          end

          it { is_expected.to be_valid }
        end
        context 'when the type is nil (unlimited)' do
          let(:params) do
            { per_process_memory_in_mb: nil }
          end

          it { is_expected.to be_valid }
        end
      end

      describe 'total_instances' do
        context 'when the type is a string' do
          let(:params) do
            { total_instances: 'bob' }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Total instances is not a number')
          end
        end
        context 'when the type is decimal' do
          let(:params) do
            { total_instances: 1.1 }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Total instances must be an integer')
          end
        end
        context 'when the type is a negative integer' do
          let(:params) do
            { total_instances: -1 }
          end

          it 'is not valid because "unlimited" is set with null, not -1, in V3' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Total instances must be greater than or equal to 0')
          end
        end

        context 'when the type is zero' do
          let(:params) do
            { total_instances: 0 }
          end

          it { is_expected.to be_valid }
        end
        context 'when the type is nil (unlimited)' do
          let(:params) do
            { total_instances: nil }
          end

          it { is_expected.to be_valid }
        end
      end

      describe 'per_app_tasks' do
        context 'when the type is a string' do
          let(:params) do
            { per_app_tasks: 'bob' }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Per app tasks is not a number')
          end
        end

        context 'when the type is decimal' do
          let(:params) do
            { per_app_tasks: 1.1 }
          end

          it 'is not valid' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Per app tasks must be an integer')
          end
        end

        context 'when the type is a negative integer' do
          let(:params) do
            { per_app_tasks: -1 }
          end

          it 'is not valid because "unlimited" is set with null, not -1, in V3' do
            expect(subject).to be_invalid
            expect(subject.errors).to contain_exactly('Per app tasks must be greater than or equal to 0')
          end
        end

        context 'when the type is zero' do
          let(:params) do
            { per_app_tasks: 0 }
          end

          it { is_expected.to be_valid }
        end

        context 'when the type is nil (unlimited)' do
          let(:params) do
            { per_app_tasks: nil }
          end

          it { is_expected.to be_valid }
        end
      end
    end
  end
end