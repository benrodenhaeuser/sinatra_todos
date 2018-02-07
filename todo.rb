require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def completed?(todos)
    todos.size > 0 && todos.all? { |todo| todo[:completed] }
  end

  def list_class(list)
    "complete" if completed?(list[:todos])
  end

  def remaining(todos)
    todos.select { |todo| !todo[:completed] }.size
  end

  def list_error_message(name)
    if name.length < 1
      "List names have to contain at least one character."
    elsif @lists.any? { |list| list[:name] == name }
      "List names have to be unique."
    end
  end

  def todo_error_message(name)
    if name.size < 1
      "Todos have to be at least one char long."
    end
  end

  def sort_lists
    incomplete_lists = {}
    complete_lists = {}

    @lists.each_with_index do |list, index|
      complete_lists[index] = list if completed?(list[:todos])
      incomplete_lists[index] = list if !completed?(list[:todos])
    end

    incomplete_lists.each { |key, value| yield(value, key) }
    complete_lists.each { |key, value| yield(value, key) }
  end

  def sort_todos(todos)
    complete_todos = {}
    incomplete_todos = {}

    todos.each_with_index do |todo, index|
      complete_todos[index] = todo if todo[:completed]
      incomplete_todos[index] = todo if !todo[:completed]
    end

    incomplete_todos.each { |key, value| yield(value, key) }
    complete_todos.each { |key, value| yield(value, key) }
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get "/" do
  puts self.instance_of?(Sinatra::Application) # true
  redirect "/lists"
end

# show all lists
get "/lists" do
  erb(:lists, layout: :layout)
end

# show new list form
get "/lists/new" do
  erb(:new_list, layout: :layout)
end

# show deleted lists
get "/lists/trash" do
  erb(:trash, layout: :layout)
end

# show list
get "/lists/:id" do
  @list_id = @params[:id].to_i
  if @list_id < @lists.size
    @list = @lists[@list_id]
    erb(:list, layout: :layout)
  else
    session[:error] = "The requested list does not exist."
    redirect "/lists"
  end
end

# show edit form for existing todo list
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = @lists[@id]
  erb(:edit_list, layout: :layout)
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = list_error_message(list_name)

  if error
    session[:error] = error
    erb(:new_list, layout: :layout)
  else
    @list_id = @lists.length
    @lists << { name: list_name, todos: [] }
    session[:success] = "List has been succesfully created!"
    redirect "/lists/#{@list_id}"
  end
end

# update existing todo list
post "/lists/:id" do
  @id = params[:id].to_i
  @list = @lists[@id]
  list_name = params[:list_name].strip
  error = list_error_message(list_name)

  if error
    session[:error] = error
    erb(:edit_list, layout: :layout)
  else
    @list[:name] = list_name
    session[:success] = "List has been succesfully renamed!"
    redirect "/lists/#{@id}"
  end
end

# create new todo
post "/lists/:id/todos" do
  @id = params[:id].to_i
  @list = @lists[@id]
  todo_name = params[:todo].strip
  error = todo_error_message(todo_name)

  if error
    session[:error] = "Todos have to contain at least one character."
    erb(:list, layout: :layout)
  else
    @list[:todos] << { name: todo_name, completed: false }
    session[:success] = "Todo has been succesfully added!"
    redirect "/lists/#{@id}"
  end
end

# mark existing list as deleted
post "/lists/:id/delete" do
  @id = params[:id].to_i
  @lists[@id][:deleted] = true
  # @lists.delete_at(@id) # ids are not stable if we do this.
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# restore list that is marked as deleted
post "/lists/:id/restore" do
  @id = params[:id].to_i
  @lists[@id][:deleted] = false
  session[:success] = "The list has been restored."
  redirect "/lists/#{@id}"
end

# delete a todo
post "/lists/:id/todos/:todo_id/delete" do
  @list_id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  @lists[@list_id][:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# mark all todos as completed
post "/lists/:id/todos/complete_all" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  todos = @list[:todos]

  todos.each { |todo| todo[:completed] = true }
  session[:success] = "The todos have been marked completed."
  redirect "/lists/#{@list_id}"
end

# update complete status of a todo
post "/lists/:id/todos/:todo_id" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  todo_id = params[:todo_id].to_i
  new_todo_status = (params[:completed] == 'true')
  @list[:todos][todo_id][:completed] = new_todo_status
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end
