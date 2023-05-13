# frozen_string_literal: true

describe Cask::Utils do
  let(:command) { NeverSudoSystemCommand }

  describe "::gain_permissions_mkpath" do
    let(:dir) { mktmpdir }
    let(:path) { dir/"a/b/c" }

    it "creates a directory" do
      expect(path).not_to exist
      described_class.gain_permissions_mkpath path, command: command
      expect(path).to be_a_directory
      described_class.gain_permissions_mkpath path, command: command
      expect(path).to be_a_directory
    end

    context "when parent directory is not writable" do
      it "creates a directory with `sudo`" do
        FileUtils.chmod "-w", dir
        expect(dir).not_to be_writable

        expect(command).to receive(:run!).exactly(:once).and_wrap_original do |original, *args, **options|
          FileUtils.chmod "+w", dir
          original.call(*args, **options)
          FileUtils.chmod "-w", dir
        end

        expect(path).not_to exist
        described_class.gain_permissions_mkpath path, command: command
        expect(path).to be_a_directory
        described_class.gain_permissions_mkpath path, command: command
        expect(path).to be_a_directory

        expect(dir).not_to be_writable
        FileUtils.chmod "+w", dir
      end
    end
  end
end
