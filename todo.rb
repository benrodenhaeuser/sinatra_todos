require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# GET  /lists       view lists
# POST /lists       create new list
# GET  /lists/new   form for creating new list
# GET  /lists/:id   view single list

# view all lists
get "/lists" do
  @lists = session[:lists]
  erb(:lists, layout: :layout)
end

# render form for creating new list
get "/lists/new" do
  erb(:new, layout: :layout)
end

# create new list
post "/lists" do
  name = params[:list_name].strip

  if name.length > 0 &&
    session[:lists] << { name: name, todos: [] }
    session[:success] = "List has been succesfully created!"
    redirect "/lists"
  else
    session[:error] = "List names have to contain at least one character."
    erb(:new, layout: :layout)
  end
end
