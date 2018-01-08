# frozen_string_literal: true

require 'models/shared_examples/caching_method_call.rb'
require 'models/shared_examples/version_control/being_a_file_collection.rb'
require 'models/shared_examples/version_control/repository_locking.rb'

RSpec.describe VersionControl::FileCollections::Staged, type: :model do
  subject(:file_collection) { repository.stage.files }
  let(:repository)          { build :repository }
  let(:root)                { create :file, :root, repository: repository }

  it_should_behave_like 'being a file collection'

  describe 'delegations' do
    it 'delegates lock to repository' do
      subject
      expect(subject.repository).to receive :lock
      subject.lock {}
    end

    it 'delegates workdir to repository' do
      subject
      expect(subject.repository).to receive :workdir
      subject.workdir
    end
  end

  describe '#count' do
    subject(:method) { file_collection.count }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'without root' do
      it { is_expected.to eq 0 }
    end

    context 'with root' do
      before  { create_list :file, 0, parent: root }
      it      { is_expected.to eq 1 }
    end

    context 'with 3 files' do
      before  { create_list :file, 3, parent: root }
      it      { is_expected.to eq 4 }
    end
  end

  describe '#create_or_update(params)' do
    subject(:method)  { file_collection.create_or_update(params) }
    let!(:root)       { create :file, :root, repository: repository }
    let(:file_id)     { 'azzouqhpgyde3275367310' }
    let(:params) do
      {
        id: file_id,
        name: 'my file',
        mime_type: 'application/vnd.google-apps.document',
        parent_id: root.id,
        version: 5,
        modified_time: Time.zone.now
      }
    end
    let(:saved_file) { file_collection.find(params[:id]) }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when file does not yet exist' do
      it 'creates file with the id' do
        method
        expect(file_collection.find(params[:id]))
          .to be_an_instance_of VersionControl::Files::Staged
      end
    end

    context 'when file already exists' do
      let(:file)    { create :file, parent: root }
      let(:file_id) { file.id }

      it 'calls #update on the file' do
        expect_any_instance_of(VersionControl::Files::Staged)
          .to receive(:update).with(params)
        method
      end

      context 'when file is root' do
        let(:file_id) { root.id }

        it 'calls #update on root' do
          expect_any_instance_of(VersionControl::Files::Staged::Root)
            .to receive(:update).with(params)
          method
        end
      end
    end
  end

  describe '#create_root' do
    subject(:method) { file_collection.create_root(params) }
    let(:params) do
      {
        id: '123-abc-root-id',
        name: 'my file',
        mime_type: 'application/vnd.google-apps.folder',
        version: 5,
        modified_time: Time.zone.now
      }
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it { is_expected.to be_an_instance_of VersionControl::Files::Staged::Root }

    it 'creates a root folder' do
      method
      expect(file_collection.root).to have_attributes(params)
    end

    context 'when root already exists' do
      let!(:root) { create :file, :root, repository: repository }

      it 'raises ActiveRecord::RecordInvalid error' do
        expect { method }.to raise_error ActiveRecord::RecordInvalid
      end
    end
  end

  describe '#exists?(id_or_ids)' do
    subject(:method)  { file_collection.exists? id }
    let(:id)          { file.id }
    let!(:file)       { create :file, parent: root }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it { is_expected.to be true }

    context 'when file with id does not exist' do
      let(:id)  { 'does-not-exist' }
      it        { is_expected.to be false }
    end

    context 'when id is nil' do
      let(:id)  { nil }
      it        { is_expected.to be false }
    end

    context 'when multiple ids are passed' do
      let(:id) { [file.id, root.id] }

      it { is_expected.to be_a Hash }

      it 'returns true for file and root' do
        expect(method).to eq file.id => true, root.id => true
      end

      context 'when single id as array is passed' do
        let(:id) { [file.id] }

        it { is_expected.to be_a Hash }
        it { expect(method).to eq file.id => true }
      end

      context 'when some elements are nil' do
        let(:id) { [file.id, nil, root.id, nil] }

        it 'drops nil and returns true for file and root ' do
          expect(method).to eq file.id => true, root.id => true
        end
      end

      context 'when some elements are non-existent' do
        let(:id) { [file.id, 'fail', root.id, 'does not exist'] }

        it 'returns true for file and root and false for others' do
          is_expected.to include(
            file.id           =>  true,
            'fail'            =>  false,
            root.id           =>  true,
            'does not exist'  =>  false
          )
        end
      end
    end
  end

  describe '#find(id)' do
    subject(:method)  { file_collection.find file_id }
    let(:file_id)     { file.id }
    let(:file)        { create :file, parent: root }

    it_should_behave_like 'using repository locking' do
      before        { file }
      let(:locker)  { file_collection }
    end
    it { is_expected.to be_a VersionControl::Files::Staged }
    it do
      is_expected.to have_attributes(
        id: file.id,
        name: file.name,
        mime_type: file.mime_type,
        parent_id: file.parent_id,
        version: file.version,
        modified_time: file.modified_time
      )
    end

    context 'when id is root' do
      let(:file_id) { root.id }
      it 'returns an instance of root' do
        expect(method).to be_an_instance_of VersionControl::Files::Staged::Root
      end
    end

    context 'when id is nil' do
      let(:file_id) { nil }

      it 'raises ActiveRecord::RecordNotFound error' do
        expect { method }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find file with id: #{file_id}"
        )
      end
    end

    context 'when id is non existent' do
      let(:file_id) { 'non-existent-file' }

      it 'raises ActiveRecord::RecordNotFound error' do
        expect { method }.to raise_error(
          ActiveRecord::RecordNotFound,
          "Couldn't find file with id: #{file_id}"
        )
      end
    end
  end

  describe '#find_by_id(id_or_ids)' do
    subject(:method)  { file_collection.find_by_id(id) }
    let(:id)          { file.id }
    let!(:file)       { create :file, parent: root }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it { is_expected.to be_a VersionControl::Files::Staged }
    it { is_expected.to have_attributes(id: file.id, name: file.name) }

    context 'when file is a folder' do
      let!(:file) { create :file, :folder, parent: root }
      it          { is_expected.to be_a VersionControl::Files::Staged::Folder }
    end

    context 'when file is root' do
      let!(:file) { root }
      it          { is_expected.to be_a VersionControl::Files::Staged::Root }
    end

    context 'when file with id does not exist' do
      let(:id) { 'abc-does-not-exist' }
      it { is_expected.to be nil }
    end

    context 'when id is nil' do
      let(:id) { nil }
      it { is_expected.to be nil }
    end

    context 'when multiple ids are passed' do
      let(:id) { [file.id, root.id] }

      it { is_expected.to be_an Array }

      it 'returns file and root' do
        expect(method.map(&:id)).to eq [file.id, root.id]
      end

      context 'when single id as array is passed' do
        let(:id) { [file.id] }

        it { is_expected.to be_an Array }
        it { expect(method[0].id).to eq file.id }
      end

      context 'when some elements are nil' do
        let(:id) { [file.id, nil, root.id, nil] }

        it 'returns file, nil, file, and nil' do
          expect(method[0]).to be_a VersionControl::File
          expect(method[1]).to be nil
          expect(method[2]).to be_a VersionControl::File
          expect(method[3]).to be nil
        end
      end

      context 'when some elements are non-existent' do
        let(:id) { [file.id, 'fail', root.id, 'does not exist'] }

        it 'returns file, nil, file, and nil' do
          expect(method[0]).to be_a VersionControl::File
          expect(method[1]).to be nil
          expect(method[2]).to be_a VersionControl::File
          expect(method[3]).to be nil
        end
      end
    end
  end

  describe '#find_by_path(path)' do
    subject(:method)  { file_collection.find_by_path(path) }
    let(:path)        { file.path }
    let!(:file)       { create :file, parent: root }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it { is_expected.to be_a VersionControl::Files::Staged }
    it 'passes all parameters' do
      expect(VersionControl::Files::Staged).to receive(:new).with(
        file_collection,
        name: file.name,
        mime_type: file.mime_type,
        version: file.version,
        modified_time: file.modified_time,
        id: file.id,
        parent_id: root.id,
        is_root: false
        # TODO: Path should be passed to initializer
        # TODO: Path should be relative
        # path: file.path
      )
      subject
    end

    context 'when file with path does not exist' do
      let(:path) { 'abc-does-not-exist' }
      it { is_expected.to be nil }
    end

    context 'when path is nil' do
      let(:path) { nil }
      it { is_expected.to be nil }
    end
  end

  describe '#find_paths_by_ids(ids)' do
    subject(:method)  { file_collection.find_paths_by_ids(ids) }
    let(:root)      { create :file, :root, id: 'root', repository: repository }
    let(:folder)    { create :file, :folder, id: 'folder', parent: root }
    let(:subfolder) { create :file, :folder, id: 'subfolder', parent: folder }
    let!(:file)     { create :file, id: 'file', parent: subfolder }
    let(:workdir)   { repository.workdir }
    let(:ids) do
      [root.id,
       folder.id,
       subfolder.id,
       file.id]
    end

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    it 'returns paths to the files' do
      expect(method[0]).to eq "#{workdir}/root"
      expect(method[1]).to eq "#{workdir}/root/folder"
      expect(method[2]).to eq "#{workdir}/root/folder/subfolder"
      expect(method[3]).to eq "#{workdir}/root/folder/subfolder/file"
    end

    it 'globs the directory once' do
      expect(Dir).to receive(:glob).exactly(1).times.and_call_original
      subject
    end

    it 'sorts results according to passed ids' do
      ids.reverse!
      is_expected.to match [file, subfolder, folder, root].map(&:path)
    end

    context 'when ids contain GLOB metacharacters' do
      let(:ids) { ['*', '?', '[list]'] }
      it        { is_expected.to contain_exactly nil, nil, nil }
    end

    context 'when some of the ids cannot be found' do
      before { ids << 'does not exist' }

      it 'returns all the paths' do
        expect(method[0..3])
          .to match [root, folder, subfolder, file].map(&:path)
      end

      it 'sets the last entry to nil' do
        expect(method.last).to eq nil
      end
    end

    context 'when some of the ids are nil' do
      before { ids << nil }

      it 'returns all the paths' do
        expect(method[0..3])
          .to match [root, folder, subfolder, file].map(&:path)
      end

      it 'sets the last entry to nil' do
        expect(method.last).to eq nil
      end
    end
  end

  describe '#root' do
    subject(:method) { file_collection.root }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when root exists' do
      let!(:root) { create :file, :root, repository: repository }
      it do
        is_expected.to be_an_instance_of VersionControl::Files::Staged::Root
      end
      it { is_expected.to have_attributes(id: root.id, name: root.name) }

      it_behaves_like 'caching method call', :root do
        subject { file_collection }
      end
    end

    context 'when root does not exist' do
      it { is_expected.to be nil }
    end
  end

  describe '#root_id' do
    subject(:method)  { file_collection.root_id }
    let(:root_id)     { 'abc' }
    let(:path)        { ::File.expand_path root_id, repository.workdir }

    it_should_behave_like 'using repository locking' do
      let(:locker) { file_collection }
    end

    context 'when root exists' do
      before { FileUtils.touch path }
      it { is_expected.to eq root_id }

      it_behaves_like 'caching method call', :root_id do
        subject { file_collection }
      end
    end

    context 'when root does not exist' do
      it { is_expected.to be nil }
    end
  end

  describe '#metadata_for(path)' do
    subject(:method)  { file_collection.send :metadata_for, file_path }
    let(:file_path)   { root.send :path }

    it_should_behave_like 'using repository locking' do
      before        { root }
      let(:locker)  { file_collection }
    end

    context 'when path is root path' do
      let(:file_id) { root.path }
      it do
        is_expected.to eq(
          id: root.id,
          name: root.name,
          mime_type: root.mime_type,
          parent_id: nil,
          version: root.version,
          modified_time: root.modified_time,
          is_root: true
        )
      end
    end

    context 'when path is file path' do
      let(:file_path) { file.send :path }
      let(:folder)    { create :file, :folder, parent: root }
      let(:file)      { create :file, parent: folder }

      it do
        is_expected.to eq(
          id: file.id,
          name: file.name,
          mime_type: file.mime_type,
          parent_id: folder.id,
          version: file.version,
          modified_time: file.modified_time,
          is_root: false
        )
      end
    end

    context 'when path is folder path' do
      let(:file_path) { folder.send :path }
      let(:folder)    { create :file, :folder, parent: root }

      it do
        is_expected.to eq(
          id: folder.id,
          name: folder.name,
          mime_type: folder.mime_type,
          parent_id: root.id,
          version: folder.version,
          modified_time: folder.modified_time,
          is_root: false
        )
      end
    end

    context 'when path is nil' do
      let(:file_path) { nil }
      it 'raises a invalid argument error' do
        expect { method }.to raise_error(
          Errno::EINVAL,
          'Invalid argument - Path must be a String.'
        )
      end
    end
  end

  describe '#parent_id_from_absolute_file_path(path)' do
    subject(:method) do
      file_collection.send :parent_id_from_absolute_file_path, path
    end

    context 'when path is :working_directory:/abc/def' do
      let(:path)  { ::File.expand_path('abc/def', file_collection.workdir) }
      it          { is_expected.to eq 'abc' }
    end

    context 'when path is :working_directory:/abc/def/ghi' do
      let(:path)  { ::File.expand_path('abc/def/ghi', file_collection.workdir) }
      it          { is_expected.to eq 'def' }
    end

    context 'when path is in :working_directory:/abc' do
      let(:path)  { ::File.expand_path('abc', file_collection.workdir) }
      it          { is_expected.to eq nil }
    end
  end
end
