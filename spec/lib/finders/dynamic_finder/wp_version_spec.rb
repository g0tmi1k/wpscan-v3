require 'spec_helper'

expected_all = df_expected_all['wordpress']

WPScan::DB::DynamicFinders::Wordpress.create_versions_finders

describe 'Try to create the finders twice' do
  it 'does not raise an error when the class already exists' do
    expect { WPScan::DB::DynamicFinders::Wordpress.create_versions_finders }.to_not raise_error
  end
end

WPScan::DB::DynamicFinders::Wordpress.versions_finders_configs.each do |finder_class, config|
  finder_super_class = config['class'] ? config['class'] : finder_class

  describe df_tested_class_constant('WpVersion', finder_class) do
    subject(:finder) { described_class.new(target) }
    let(:target)     { WPScan::Target.new('http://wp.lab/') }
    let(:fixtures)   { File.join(DYNAMIC_FINDERS_FIXTURES, 'wp_version') }

    let(:expected)   { expected_all[finder_class] }

    let(:stubbed_response) { { body: '' } }

    describe '#passive' do
      before { stub_request(:get, target.url).to_return(stubbed_response) }

      if config['path']
        context 'when PATH' do
          it 'returns nil' do
            expect(finder.passive).to eql nil
          end
        end
      else
        context 'when no PATH' do
          let(:stubbed_response) do
            df_stubbed_response(
              File.join(fixtures, "#{finder_super_class.underscore}_passive_all.html"),
              finder_super_class
            )
          end

          it 'returns the expected version from the homepage' do
            version = finder.passive

            expect(version).to be_a WPScan::WpVersion
            expect(version.number).to eql expected['number'].to_s
            expect(version.found_by).to eql expected['found_by']
            expect(version.interesting_entries).to match_array expected['interesting_entries']

            expect(version.confidence).to eql expected['confidence'] if expected['confidence']
          end
        end
      end
    end

    describe '#aggressive' do
      let(:fixtures) { File.join(super(), finder_class.underscore) }

      before do
        allow(target).to receive(:sub_dir).and_return(nil)

        stub_request(:get, target.url(config['path'])).to_return(stubbed_response) if config['path']
      end

      if config['path']
        context 'when the version is detected' do
          let(:stubbed_response) do
            df_stubbed_response(File.join(fixtures, config['path']), finder_super_class)
          end

          it 'returns the expected version' do
            version = finder.aggressive

            expect(version).to be_a WPScan::WpVersion
            expect(version.number).to eql expected['number'].to_s
            expect(version.found_by).to eql expected['found_by']
            expect(version.interesting_entries).to match_array expected['interesting_entries']

            expect(version.confidence).to eql expected['confidence'] if expected['confidence']
          end
        end

        context 'when the version is not detected' do
          # TODO: Maybe a no_version.ext file in the fixtures dir to make
          # sure the pattern doesn't match some junk ?
          it 'returns nil' do
            expect(finder.aggressive).to eql nil
          end
        end
      else
        it 'returns nil' do
          expect(finder.aggressive).to eql nil
        end
      end
    end
  end
end
