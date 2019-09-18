#!/usr/bin/env ruby

require 'json'
require 'readline'

user_dir = ENV['HOME']
task_file = user_dir + '/.rubydo.json'

SHOW_DELETED_TASKS = true

class Colorize
	def self.black(text)
		return "\e[30m#{text}\e[0m"
	end
	def self.red(text)
		return "\e[31m#{text}\e[0m"
	end
	def self.green(text)
		return "\e[32m#{text}\e[0m"
	end
	def self.yellow(text)
		return "\e[33m#{text}\e[0m"
	end
	def self.blue(text)
		return "\e[34m#{text}\e[0m"
	end
	def self.magenta(text)
		return "\e[35m#{text}\e[0m"
	end
	def self.cyan(text)
		return "\e[36m#{text}\e[0m"
	end
	def self.gray(text)
		return "\e[37m#{text}\e[0m"
	end

	def self.bg_black(text)       
		return "\e[40m#{text}\e[0m"
	end
	def self.bg_red(text)         
		return "\e[41m#{text}\e[0m"
	end
	def self.bg_green(text)       
		return "\e[42m#{text}\e[0m"
	end
	def self.bg_yellow(text)       
		return "\e[43m#{text}\e[0m"
	end
	def self.bg_blue(text)        
		return "\e[44m#{text}\e[0m"
	end
	def self.bg_magenta(text)     
		return "\e[45m#{text}\e[0m"
	end
	def self.bg_cyan(text)        
		return "\e[46m#{text}\e[0m"
	end
	def self.bg_gray(text)        
		return "\e[47m#{text}\e[0m"
	end

	def self.bold(text)           
		return "\e[1m#{text}\e[22m"
	end
	def self.italic(text)         
		return "\e[3m#{text}\e[23m"
	end
	def self.underline(text)      
		return "\e[4m#{text}\e[24m"
	end
	def self.blink(text)          
		return "\e[5m#{text}\e[25m"
	end
	def self.reverse_color(text)  
		return "\e[7m#{text}\e[27m"
	end
end

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

	def to_hash
		taskhash = {'task' => @task, 'status' => @status, 'timestamp' => @timestamp}
		return taskhash
	end

	def to_json
		return self.to_hash.to_json
	end
end

class Tasklist
	attr_accessor :autosave
	attr_accessor :backing_file
	attr_accessor :tasks

	def initialize(backing_file)
		@backing_file = File.expand_path(backing_file)
		@tasks = Array.new
		@open_tasks = Array.new
		@closed_tasks = Array.new
		@dirty=false
		@autosave = true
		self.load(@backing_file)
	end

	def is_dirty?
		return @dirty
	end

	def add(item)
		# Add to tasklist
		if !(@tasks.map { |x| x.task }).include?(item)
			@tasks.push(Task.new(item))
			@dirty = true
		end
	end

	def complete(item)
		# Complete item in tasklist
		for task in tasks
			if task.task == item && task.status == 1
				task.status = 0
				@dirty = true
			end
		end
	end

	def reopen(item)
		for task in tasks
			if task.task == item && task.status == 0
				task.status = 1
				@dirty = true
			end
		end
	end

	def delete(item)
		@tasks.delete_if { |t| t.task == item }
		@dirty = true 
	end

	def save(file=backing_file)
		storage = File.open(file, 'w')
		storage.write(self.to_json)
		storage.close
		@dirty = false
	end

	def load(file)
		if File.exists?(file)
			if File.empty?(file)
				puts "nothing to load!!"
			else
				data_hash = JSON.parse(File.read(file))
				self.autosave = data_hash['autosave']
				for datum in data_hash['tasks']
					task = Task.new(datum['task'])
					task.status = datum['status'].to_i
					task.timestamp = datum['timestamp']
					@tasks.push(task)
				end
			end
		end
	end

	def flush(item)
		if item.downcase == '-y'
			response = true
		else
			response = Readline.readline("Are you sure you want to delete ALL tasks? [y/N]: ").chomp
			response.downcase == 'y' ? response = true : response = false
		end

		if response
			@tasks.clear
			@dirty = true
		end
		Gem.win_platform? ? (system "cls") : (system "clear")
	end

	def user_select(item)
		if item.count > 1
			Gem.win_platform? ? (system "cls") : (system "clear")
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
		puts Colorize.yellow("Fuzzy match found: #{results}")
		return results
	end

	def show_tasks(show_completed=false)
		status = [' ✓', '']
		if !@tasks.empty?
			@open_tasks.clear
			@closed_tasks.clear

			# Sort tasks into Open / Closed
			@tasks.map { |t| t.status == 1 ? @open_tasks.push(t) : @closed_tasks.push(t) }

			# print open tasks
			puts "Open Tasks:"
			@open_tasks.map { |task| puts "\t- #{task.task}#{status[task.status]}" }
			
			# print closed tasks
			puts "Closed Tasks:"
			@closed_tasks.map { |task| puts "\t- #{task.task}#{status[task.status]}" }
		end
	end

	def to_json
		taskshash = { 'autosave' => @autosave, 'tasks' => @tasks.map { |t| t.to_hash } }
		taskshash.to_json
	end

end

tl = Tasklist.new(task_file)

def print_menu(task_list, menu)
	task_list.show_tasks
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
		puts Colorize.cyan("adding #{item}")
		tl.add(item)
	when /^(c|co|com|comp|compl|comple|complet|complete)$/
		item = tl.user_select(tl.fuzzy_match(item))
		puts Colorize.cyan("marking #{item} complete")
		tl.complete(item)
	when /^(r|re|reo|reop|reope|reopen)$/
		item = tl.user_select(tl.fuzzy_match(item))
		puts Colorize.green("reopening #{item}")
		tl.reopen(item)
	when /^(d|de|del|dele|delet|delete)$/
		item = tl.user_select(tl.fuzzy_match(item))
		puts Colorize.red("deleting #{item}")
		tl.delete(item)
	when /^(q|qu|qui|quit)$/
		return 'q'
	# Other commands
	when /^(cm|cmd)$/
		begin
			print "\e[35m"
			eval(item)
			puts "\e[0m"
		rescue StandardError => e
			print "\e[31m" 
			puts e.message
			puts e.backtrace.inspect
			puts"\e[0m"
		end
	when /^(f|fl|flu|flus|flush)$/
		tl.flush(item)
	when /^(s|sa|sav|save)$/
		puts Colorize.green("[Saved]")
		tl.save
	else
		puts "#{action} is not a valid action" # Throw error and do nothing
	end

	return action[0].downcase
end

def run_interactive(tl)
	Gem.win_platform? ? (system "cls") : (system "clear")
	# initialize response
	resp = ''
	# menu items to display
	menu = ["[A]dd <task>", "[C]omplete <task>", "[D]elete <task>", "[Q]uit"]
	
	# infinite loop of interactivity
	while(resp != 'q')
		print_menu(tl, menu)		# reset response item
		resp = ''
		resp = Readline.readline("> ").strip
		resp = process_response(tl, resp, SHOW_DELETED_TASKS)
		if tl.is_dirty? && tl.autosave
			tl.save
		end
	end
end

if !ARGV.empty?
	action = ARGV[0]
	item = ARGV.drop(1).join(" ")
	puts "You entered #{ARGV.join(" ")}"
	case action.downcase
	when /^(s|sh|sho|show|p|pr|pri|prin|print)$/
		puts "printing not implemented"
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