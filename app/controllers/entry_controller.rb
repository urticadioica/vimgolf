class EntryController < ApplicationController

  before_filter :login, :only => [:comment]
  before_filter :load_entry, :only => [:comment]

  def comment
    begin
      if @challenge.participator?(current_user) && params[:comment] && params[:comment][:text].size > 0
        @entry.comments.push Comment.new(:comment => params[:comment][:text], :nickname => current_user.nickname)
        @challenge.save
      end

    rescue Exception => e
    ensure
      redirect_to challenge_path(params[:challenge])
    end
  end

  def create
    if params[:entry] && params[:entry].size < 2
      @cheat = true

    elsif params['challenge_id'] && !params['apikey'].empty? && !params['apikey'].nil?
      @challenge = Challenge.find(params['challenge_id']) rescue nil
      @user = User.first(:conditions => {:key => params['apikey']}) rescue nil

      if @challenge && @user
        @entry = Entry.new(
                  :script => params[:entry],
                  :score => VimGolf::Keylog.new(params[:entry]).score
                 )
        @entry.created_at = Time.now.utc
        @entry.user = @user

        @challenge.entries << @entry
      end
    end

    respond_to do |format|
      if !@cheat && @user && @challenge && @challenge.save
        format.json { render :json => {'status' => 'ok'} }
      else
        format.json { render :json => {'status' => 'failed'}, :status => 400 }
      end
    end
  end

  def destroy
    begin
      challenge = Challenge.find(params[:challenge])
      entry = challenge.entries.find(params[:entry])

      if challenge.owner?(current_user) || entry.owner?(current_user)
        entry.destroy
        challenge.save

        flash[:notice] = "Deleted entry"
      end

      redirect_to challenge_path(params[:challenge])
    rescue Exception => e
      redirect_to root_path
    end
  end

  private

    def load_entry
      begin
        @challenge = Challenge.find(params[:challenge])
        @entry = @challenge.entries.find(params[:entry])

      rescue Exception => e
        respond_to do |format|
          format.json {
            render :json => {'status' => 'failed'}, :status => 400
          }
          format.html { redirect_to root_path }
        end
      end
    end

end
