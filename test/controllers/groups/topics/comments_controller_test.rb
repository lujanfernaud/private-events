# frozen_string_literal: true

require 'test_helper'

class Groups::Topics::CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @comment = topic_comments(:one)
    @topic   = @comment.topic
    @group   = @topic.group
    @phil    = users(:phil)
  end

  test "should create comment" do
    sign_in @phil

    assert_difference('TopicComment.count') do
      post group_topic_comments_url(@group, @topic), params: comment_params
    end

    assert_redirected_to group_topic_url(@group, @topic)
  end

  test "should get edit" do
    sign_in @phil

    get edit_comment_url(@comment)

    assert_response :success
  end

  test "should update comment" do
    sign_in @phil

    new_params = comment_params.merge({ topic_comment: { body: "Oh! Hai!" } })

    patch comment_url(@comment), params: new_params

    assert_redirected_to group_topic_url(@group, @topic)
  end

  test "should destroy comment" do
    sign_in @phil

    assert_difference('TopicComment.count', -1) do
      delete comment_url(@comment)
    end

    assert_redirected_to group_topic_url(@group, @topic)
  end

  private

    def comment_params
      {
        topic_comment: {
          body: "Hello!"
        }
      }
    end
end