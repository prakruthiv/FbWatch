require 'spec_helper'

describe "Apitests" do
  subject { page }

  describe "GET /apitests" do
    before { visit apitest_path }
    it { should have_selector('h1', text: "Login") }
    #it { should have_field('query') }
  end
end
