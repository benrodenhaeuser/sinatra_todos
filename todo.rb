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

# render new list form
get "/lists/new" do
  erb(:new_list, layout: :layout)
end

# render new todo form
get "/lists/:id/new" do
  @id = params[:id].to_i
  erb(:new_todo, layout: :layout)
end

# view single list
get "/lists/:id" do
  @id = params[:id].to_i
  if @id < @lists.size
    @list = @lists[@id]
    erb(:list, layout: :layout)
  else
    session[:error] = "The requested list does not exist."
    redirect "/lists"
  end 
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  if list_name.length > 0
    @lists << { name: list_name, todos: [] }
    session[:success] = "List has been succesfully created!"
    redirect "/lists"
  else
    session[:error] = "List names have to contain at least one character."
    erb(:new_list, layout: :layout)
  end
end

# create new todo
post "/lists/:id" do
  @id = params[:id].to_i
  @list = @lists[@id]
  todo = params[:todo].strip

  if todo.length > 0
    @list[:todos] << todo
    session[:success] = "Todo has been succesfully added!"
    redirect "/lists/#{@id}"
  else
    session[:error] = "Todos have to contain at least one character."
    erb(:new_todo, layout: :layout)
  end
end
