require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do
  # VIEW HELPERS

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
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }

    incomplete_todos.each { |todo| yield(todo) }
    complete_todos.each { |todo| yield(todo) }
  end

  # ROUTE HELPERS

  def load_list(id)
    list = @lists.find { |list| list[:id] == id.to_i }
    return list if list

    session[:error] = "The requested list was not found."
    redirect "/lists"
  end

  def next_todo_id(todos)
    max = todos.map { |todo| todo[:id] }.max || 0
    max + 1
  end

  def find_todo_by_id(list, id)
    list[:todos].find { |todo| todo[:id] == id }
  end

  def next_list_id
    max = @lists.map { |list| list[:id] }.max || 0
    max + 1
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get "/" do
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

# show list
get "/lists/:id" do
  @list_id = params[:id].to_s
  @list = load_list(params[:id])
  erb(:list, layout: :layout)
end

# show edit form for existing todo list
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @list = load_list(params[:id])
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
    @list_id = next_list_id
    @lists << { name: list_name, todos: [], id: @list_id }
    session[:success] = "List has been succesfully created!"
    redirect "/lists/#{@list_id}"
  end
end

# update existing todo list
post "/lists/:id" do
  @id = params[:id].to_i
  @list = load_list(params[:id])
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
  @list = load_list(params[:id])
  todo_name = params[:todo].strip
  error = todo_error_message(todo_name)

  if error
    session[:error] = "Todos have to contain at least one character."
    erb(:list, layout: :layout)
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << { id: id, name: todo_name, completed: false }
    session[:success] = "Todo has been succesfully added!"
    redirect "/lists/#{@id}"
  end
end

# delete todo list
post "/lists/:id/delete" do
  @id = params[:id].to_i
  @lists.delete(load_list(params[:id]))
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# delete a todo
post "/lists/:id/todos/:todo_id/delete" do
  @list_id = params[:id].to_i
  todo_id = params[:todo_id].to_i
  todo = find_todo_by_id(load_list(params[:id]), todo_id)
  @lists[@list_id][:todos].delete(todo)
  if env["HTTP_X_REQUESTED_WITH"] == 'XMLHttpRequest'
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
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
  todo = find_todo_by_id(load_list(params[:id]), todo_id)
  todo[:completed] = new_todo_status
  session[:success] = "The todo has been updated."

  redirect "/lists/#{@list_id}"
end
