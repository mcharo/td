#!/usr/bin/env ruby

require 'json'

SHOW_DELETED_TASKS = true

user_dir = ENV['HOME']
todo_file = user_dir + '/.rubydo.rb'

# puts "checking for backing file: #{todo_file}"

# TODO: Need to figure out showing deleted tasks.
class TodoList

	@backing_file
	@open_tasks
	@closed_tasks

	def initialize(tdfile)
		@backing_file = tdfile
		@open_tasks = Hash.new
		@closed_tasks = Hash.new
		# Need to see if files exists
		# Load values
	end 

	def add_task(key)
		@open_tasks.store(key, Time.new)
	end

	def complete_task(key)
		if @open_tasks.delete(key)
			@closed_tasks.store(key, Time.new)
		end
		
	end

	def reopen_task(key)
		if @closed_tasks.delete(key)
			@open_tasks.store(key, Time.new)
		end
	end

	def delete_task(key)
		@closed_tasks.delete(key)
		@open_tasks.delete(key)
	end

	def save_tasks(path=@backing_file)
		# write to json file
	end

	def show_tasks(show_deleted=si)
		if !@open_tasks.empty?
			puts "Open Tasks:"
			@open_tasks.keys.each_with_index.map { |task,i| puts "\t#{i}. #{task}"}
		else
			puts "No Open Tasks"
		end
		if show_deleted
			if !@closed_tasks.empty?
				puts "Closed Tasks"
				@closed_tasks.keys.each_with_index.map { |task,i| puts "\t#{i}. #{task}"}
			else
				puts "No Closed Tasks"
			end
		end
	end

end

# puts "creating task list"
todolist = TodoList.new (todo_file) 


def print_menu(menu)
	puts "please use the following commands: "
	puts "   #{menu.join(", ")}"
	print "> "
end

def process_response(tl, resp, sdt)
	Gem.win_platform? ? (system "cls") : (system "clear")
	#puts "You entered \"#{resp}\""

	if resp.empty?
		return
	end

	elements = resp.split(" ")
	action = elements[0]
	item = elements.drop(1).join(" ")

	# need to do work here
	case action.downcase
	when /^(a|ad|add)$/
		puts "adding #{item}"
		tl.add_task(item)
	when /^(c|co|com|comp|compl|comple|complet|complete)$/
		puts "marking #{item} complete"
		tl.complete_task(item)
	when /^(r|re|reo|reop|reope|reopen)$/
		puts "reopening #{item}"
		tl.reopen_task(item)
	when /^(d|de|del|dele|delet|delete)$/
		puts "deleting #{item}"
		tl.delete_task(item)
	when /^(q|qu|qui|quit)$/
		return 'q'
	else
		puts "#{action} is not a valid action" # Throw error and do nothing
	end

	puts tl.show_tasks(sdt)

	return action[0].downcase
end

def run_interactive(tl)
	Gem.win_platform? ? (system "cls") : (system "clear")
	# initialize response
	resp = ''
	# menu items to display
	menu = ['Add <task>', 'Complete <task>', 'Delete <task>', 'Quit']
	
	# infinite loop of interactivity
	while(resp != 'q')
		print_menu menu
		# reset response item
		resp = ''
		resp = gets.strip
		resp = process_response(tl, resp, SHOW_DELETED_TASKS)
	end
end

if !ARGV.empty?
	action = ARGV[0]
	item = ARGV.drop(1).join(" ")
	puts "You entered #{ARGV.join(" ")}"
	case action.downcase
	when /^(s|sh|sho|show|p|pr|pri|prin|print)$/
		puts "printing"
	when /^(a|ad|add)$/
		puts "adding"
	when /^(c|co|com|comp|compl|comple|complet|complete)$/
		puts "closing"
	when /^(d|de|del|dele|delet|delete)$/
		puts "deleting"
	else
		puts "unknown command: #{ARGV[0]}"
	end

	todolist.show_tasks(SHOW_DELETED_TASKS)

else
	run_interactive(todolist)
end