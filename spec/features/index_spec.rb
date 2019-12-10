# frozen_string_literal: true

require 'spec_helper'

describe 'index', type: :feature do
  before do
    visit '/'
  end

  subject { page }

  context 'without contentful data', js: true do
    it { is_expected.to have_selector('img[src*=theguild-logo]') }
    it { is_expected.to have_content(/The Guild — A Blog About Development and Geekery/i) }
    it { is_expected.to have_content(/Written by Kabisa/i) }
  end
end
