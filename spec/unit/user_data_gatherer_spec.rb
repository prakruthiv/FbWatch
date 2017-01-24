require 'spec_helper'

describe Sync::UserDataGatherer do
  it "should return empty result if error json received (top-level)" do
    facebook = double("koala")
    facebook.should_receive(:get_object).and_return({
      "name" => "name",
      "username" => "username",
      "link" => "link",
      "id" => "id"
    })

    api_error = { "error" => {
      "message" => "test error occured (OAuthException)",
      "code" => "17"
    }}

    facebook.should_receive(:api).with('/username/feed').and_return(api_error)

    gatherer = Sync::UserDataGatherer.new("username", facebook)
    data = gatherer.start_fetch
    data.should have_key(:feed)
    data[:feed].should have_key(:data)
    data[:feed].should have_key(:error)
    data[:feed][:data].should eq []
    data[:feed][:error].should eq api_error["error"]

  end

  it "should fetch comments and likes" do
    class Sync::UserDataGatherer
      public :get_all_comments_and_likes_for
    end

    facebook = double("koala")
    facebook.stub(:api).and_return({ data: "some data" })
    gatherer = Sync::UserDataGatherer.new("username", facebook)

    result = gatherer.get_all_comments_and_likes_for([
      {'id' => '123', 'comments' => {'data' => [1]}, 'likes' => {'data' => [1], 'count' => 10}},
      {'id' => '456', 'comments' => {'data' => [555]}, 'likes' => {'data' => [1], 'count' => 10}}
    ])

    result.should eq true
  end

  it "should detect duplicate queries even if nested calls were made" do
    class Sync::UserDataGatherer
      public :call_history, :api_query_already_sent?
    end
    
    gatherer = Sync::UserDataGatherer.new("1", nil)
    gatherer.page_limit = 25

    gatherer.call_history('/1/feed')
    gatherer.api_query_already_sent?('/1/feed?limit=25').should eq false

    gatherer.call_history('/123/comments')
    gatherer.api_query_already_sent?('/123/comments?limit=25').should eq false

    gatherer.call_history('/123/likes')
    gatherer.api_query_already_sent?('/123/likes?limit=25').should eq false

    gatherer.call_history('/1/feed')
    gatherer.api_query_already_sent?('/1/feed?limit=25').should eq true
    
    gatherer.call_history('/1/feed')
    gatherer.api_query_already_sent?('/123/likes?limit=25').should eq false
  end

  it "should generate only valid URIs" do
    class Sync::UserDataGatherer
      public :change_query_for_unknown_error, :create_next_query
    end

    gatherer = Sync::UserDataGatherer.new('1', nil)

    graph_link = '/VolkerBeckMdB/feed?limit=900&until=1365067411'
    graph_link = graph_link[ graph_link.index('?')+1..-1 ] if !graph_link.nil? and graph_link.index('?') > 0

    gatherer.create_next_query("", graph_link).should eq graph_link
  end
end