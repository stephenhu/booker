class Invite < ActionMailer::Base

  include IcsHelper

  default from: "no-reply-booker@vmware.com"

  def meeting_invite(meeting)


  end

  def meeting_cancel(meeting)
  end

