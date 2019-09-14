#!/usr/bin/env ruby

require 'json'
require 'readline'

user_dir = ENV['HOME']
task_file = user_dir + '/.rubydo.json'

SHOW_DELETED_TASKS = true

class Task
	include Comparable

	attr_accessor :task
	attr_accessor :status
	attr_accessor :timestamp

	def <=>(other)
		@timestamp <=> other.timestamp
	end

	def initialize(task)
		@task = task
		@status = 1
		@timestamp = Time.new
	end
end

class Tasklist
	attr_accessor :backing_file
	attr_accessor :tasks

	def initialize(backing_file)
		@backing_file = backing_file
		@tasks = Array.new
		@open_tasks = Array.new
		@closed_tasks = Array.new
	end

	def add(item)
		# Add to tasklist
		if !(@tasks.map { |x| x.task }).include?(item)
			@tasks.push(Task.new(item))
		end
	end

	def complete(item)
		# Complete item in tasklist
		item = user_select(fuzzy_match(item))
		for task in tasks
			if task.task == item && task.status == 1
				task.status = 0
			end
		end
	end

	def reopen(item)
		item = user_select(fuzzy_match(item))
		for task in tasks
			if task.task == item && task.status == 0
				task.status = 1
			end
		end
	end

	def delete(item)
		item = user_select(fuzzy_match(item))
		@tasks.delete_if { |t| t.task == item } 
	end

	def user_select(item)
		if item.count > 1
			# build prompt, request user to select
			puts "Please select from the following:"
			item.each_with_index.map { |x, i| puts "   #{i}. #{x}" }
			selection = Readline.readline("> ").chomp.to_i

			# TODO: Harden
			Gem.win_platform? ? (system "cls") : (system "clear")
		else
			selection = 0
		end
		return item[selection]
	end

	def fuzzy_match(item)
		results = []
		@tasks.map { |t| t.task.include?(item) ? results.push(t.task) : nil }
		puts "found: #{results}"
		return results
	end

	def show_tasks(show_deleted=false)
		status = [' ✓', '']
		if !@tasks.empty?
			#@tasks.each_with_index.map { |task, i| puts "#{i}. #{task.task}#{status[task.status]}" }
			@open_tasks.clear
			@closed_tasks.clear
			#@tasks.map { |task| task.status = 1 ? @open_tasks.push(task) : @closed_tasks.push(task) }

			@tasks.map { |t| t.status == 1 ? @open_tasks.push(t) : @closed_tasks.push(t) }

			# print open tasks
			puts "Open Tasks:"
			@open_tasks.map { |task| puts "\t- #{task.task}#{status[task.status]}" }
			
			# print closed tasks
			puts "Closed Tasks:"
			@closed_tasks.map { |task| puts "\t- #{task.task}#{status[task.status]}" }
		end
	end
end



tl = Tasklist.new(task_file)

def print_menu(menu)
	puts "please use the following commands: "
	puts "   #{menu.join(", ")}"
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
		tl.add(item)
	when /^(c|co|com|comp|compl|comple|complet|complete)$/
		puts "marking #{item} complete"
		tl.complete(item)
	when /^(r|re|reo|reop|reope|reopen)$/
		puts "reopening #{item}"
		tl.reopen(item)
	when /^(d|de|del|dele|delet|delete)$/
		puts "deleting #{item}"
		tl.delete(item)
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
		resp = Readline.readline("> ").strip
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

	tl.show_tasks(SHOW_DELETED_TASKS)

else
	run_interactive(tl)
end