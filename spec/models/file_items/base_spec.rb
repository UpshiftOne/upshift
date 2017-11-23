# frozen_string_literal: true

require 'models/shared_examples/being_a_file_item.rb'

RSpec.describe FileItems::Base, type: :model do
  subject(:base) { build(:file_items_base) }

  it 'has a valid factory' do
    is_expected.to be_valid
  end

  it_should_behave_like 'being a file item'

  context 'Single Table Inheritance Mime Types' do
    before { allow(NotificationChannelJob).to receive(:perform_later) }
    subject(:first_item)  { FileItems::Base.first }
    before                { create :file_items_base, mime_type: folder_type }

    context 'when mime type is folder' do
      let(:folder_type) { 'application/vnd.google-apps.folder' }
      it { is_expected.to be_a FileItems::Folder }
    end

    context 'when mime type is document' do
      let(:folder_type) { 'application/vnd.google-apps.document' }
      it { is_expected.to be_a FileItems::Document }
    end

    context 'when mime type is spreadsheet' do
      let(:folder_type) { 'application/vnd.google-apps.spreadsheet' }
      it { is_expected.to be_a FileItems::Spreadsheet }
    end

    context 'when mime type is presentation' do
      let(:folder_type) { 'application/vnd.google-apps.presentation' }
      it { is_expected.to be_a FileItems::Presentation }
    end

    context 'when mime type is drawing' do
      let(:folder_type) { 'application/vnd.google-apps.drawing' }
      it { is_expected.to be_a FileItems::Drawing }
    end

    context 'when mime type is form' do
      let(:folder_type) { 'application/vnd.google-apps.form' }
      it { is_expected.to be_a FileItems::Form }
    end

    context 'when mime type is anything else' do
      let(:folder_type) { 'some-imaginary-mime-type' }
      it { is_expected.to be_a FileItems::Base }
    end

    context 'when mime type is empty' do
      let(:folder_type) { '' }
      it { is_expected.to be_a FileItems::Base }
    end
  end

  describe '#external_link' do
    subject(:method) { base.external_link }

    context "when google drive id is 'abc'" do
      before { base.google_drive_id = 'abc' }
      it { is_expected.to eq 'https://drive.google.com/file/d/abc' }
    end

    context "when google drive id is '1234'" do
      before { base.google_drive_id = '1234' }
      it { is_expected.to eq 'https://drive.google.com/file/d/1234' }
    end
    context 'when google drive id is nil' do
      before { base.google_drive_id = nil }
      it { is_expected.to eq nil }
    end
  end

  describe '#icon' do
    context 'when mime type is abc' do
      before { subject.mime_type = 'abc' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'abc'
        )
      }
    end

    context 'when mime type is application/vnd.google-apps.12345' do
      before { subject.mime_type = 'application/vnd.google-apps.12345' }
      it {
        expect(subject.icon).to eq(
          'https://drive-thirdparty.googleusercontent.com/128/type/' \
          'application/vnd.google-apps.12345'
        )
      }
    end

    context 'when mime_type is nil' do
      before { subject.mime_type = nil }
      it { expect(subject.icon).to eq nil }
    end
  end
end
