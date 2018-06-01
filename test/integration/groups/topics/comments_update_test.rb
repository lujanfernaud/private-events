require 'test_helper'

class CommentsUpdateTest < ActionDispatch::IntegrationTest
  include TopicsIntegrationSupport

  def setup
    @group   = groups(:one)
    @phil    = users(:phil)
    @topic   = topics(:one)
    @comment = topic_comments(:one)

    prepare_javascript_driver
  end

  test "author updates comment" do
    log_in_as @phil

    visit group_topic_path(@group, @topic)

    click_on_edit

    update_comment_with "Revised comment."

    assert page.has_content? "Comment updated."
  end

  test "organizer can update comment" do
    user = users(:woodell)
    @group.add_to_organizers user

    log_in_as user

    visit group_topic_path(@group, @topic)

    click_on_edit

    update_comment_with "Revised comment."

    assert page.has_content? "Comment updated."
  end

  test "regular user can't update comment" do
    user = users(:carolyn)
    @group.members << user
    @group.remove_from_organizers user

    log_in_as user

    visit group_topic_path(@group, @topic)

    within "#comment-#{@comment.id}" do
      refute page.has_link? "Edit"
    end
  end

  private

    def click_on_edit
      within "#comment-#{@comment.id}" do
        click_on "Edit"
      end
    end
end