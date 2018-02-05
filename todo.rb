require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get "/" do
  redirect "/lists"
end

# view all lists
get "/lists" do
  erb(:lists, layout: :layout)
end

# render form for creating new list
get "/lists/new" do
  erb(:new, layout: :layout)
end

# helper for post lists route
def error_message(name)
  if name.length < 1
    "List names have to contain at least one character."
  elsif @lists.any? { |list| list[:name] == name }
    "List names have to be unique."
  end
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_message(list_name)

  if error
    session[:error] = error
    erb(:new, layout: :layout)
  else
    @lists << { name: list_name, todos: [] }
    session[:success] = "List has been succesfully created!"
    redirect "/lists"
  end
end
