using Plots
using Printf

mutable struct Cells
	field::Vector{Vector{Dict{String, Int64}}}
	size_x::Int64
	size_y::Int64
	animals::Vector{String}
end

struct AnimalInCell
	quantity::Int64
	pos_x::Int64
	pos_y::Int64
	animal::String
end

function empty_cell(animals::Vector{String})
	cell = Dict{String, Int64}()
	for animal in animals
		cell[animal] = 0
	end
	return cell
end

function empty_cells(size_x::Int64, size_y::Int64, animals::Vector{String})
	cellArray = Vector{Vector{Dict{String, Int64}}}(undef, size_x)
	for i = 1:size_x
		cellArray[i] = Vector{Dict{String, Int64}}(undef, size_y)
		for j = 1:size_y
			cellArray[i][j] = empty_cell(animals)
		end
	end
	return Cells(cellArray, size_x, size_y, animals)
end

function animal_matrix_to_plot(cells::Cells, animal::String)
	animal_vector = map((row) -> map((cell) -> cell[animal], row), cells.field)
	animal_matrix = stack(animal_vector, dims=1)
	return animal_matrix
end

function get_heatmap_plot(animal_matrix::Matrix{Int64}, animal::String)
	tittle = animal*" Population"
	return heatmap(
		1:size(animal_matrix, 1),
	    1:size(animal_matrix, 2), 
	    animal_matrix,
	    c=cgrad([:blue, :yellow, :red]),
	    xlabel="x values", ylabel="y values",
	    title=tittle)
end

function random_walk(cells::Cells, animal::String, x::Int64, y::Int64)
	animal_count = cells.field[x][y][animal]
	size_x = cells.size_x
	size_y = cells.size_y
	for i = 1:animal_count
		chance = rand(1:100)
		if chance > 0 && chance <= 20 && y + 1 <= size_y
			cells.field[x][y][animal] = cells.field[x][y][animal] - 1
			cells.field[x][y + 1][animal] = cells.field[x][y + 1][animal] + 1 
		elseif chance > 20 && chance <= 40 && y > 1
			cells.field[x][y][animal] = cells.field[x][y][animal] - 1
			cells.field[x][y - 1][animal] = cells.field[x][y - 1][animal] + 1
		elseif chance > 40 && chance <= 60 && x + 1 <= size_x
			cells.field[x][y][animal] = cells.field[x][y][animal] - 1
			cells.field[x + 1][y][animal] = cells.field[x + 1][y][animal] + 1
		elseif chance > 60 && chance <= 80 && x > 1
			cells.field[x][y][animal] = cells.field[x][y][animal] - 1
			cells.field[x - 1][y][animal] = cells.field[x - 1][y][animal] + 1
		end
	end
end

function reproduce(cells::Cells, animal::String, x::Int64, y::Int64)
	animal_count = cells.field[x][y][animal]
	chance = rand(1:100)
	if animal_count > 1 && chance < 60
		cells.field[x][y][animal] += 1
	end
end

function die_of_overpopulation(cells::Cells, animal::String, x::Int64, y::Int64)
	animal_count = cells.field[x][y][animal]
	if animal_count > 10 && chance < 50
		cells.field[x][y][animal] -= 4
		if cells.field[x][y][animal] < 0
			cells.field[x][y][animal] = 0
		end
	end
end

function simulate_animal(cells::Cells, animal::String, x::Int64, y::Int64)
	if !(animal in cells.animals)
		return
	end
	if cells.field[x][y][animal] <= 0
		return
	end

	random_walk(cells, animal, x, y)
	reproduce(cells, animal, x, y)
	die_of_overpopulation(cells, animal, x, y)
end

function simulate(cells::Cells, size_x::Int64, size_y::Int64)
	for x = (1:size_x)
		for y = (1:size_y)
			for animal in cells.animals
				simulate_animal(cells, animal, x, y)
			end
		end
	end
end

function read_pops_csv()
	f = open("pops.csv", "r")
	animals_in_cell = Vector{AnimalInCell}()
	lines = readlines(f)
	size_string = split(lines[1], ",")
	size_x = parse(Int64, size_string[1])
	size_y = parse(Int64, size_string[2])
	
	for line in lines[2:end]
		values = split(line, ",")
		quantity = parse(Int64, values[1])
		pos_x = parse(Int64, values[2])
		pos_y = parse(Int64, values[3])
		animal = values[4]
		push!(animals_in_cell, AnimalInCell(quantity, pos_x, pos_y, animal))
	end
	close(f)
	
	animals = map((animals_in_cell)->animals_in_cell.animal, animals_in_cell)
	cells = empty_cells(size_x, size_y, animals)

	for animal_in_cell in animals_in_cell
		x = animal_in_cell.pos_x
		y = animal_in_cell.pos_y
		animal = animal_in_cell.animal
		cells.field[x][y][animal] = animal_in_cell.quantity
	end
	return cells
end

cells = read_pops_csv()

iterations = 5
animal = "deer"

for i = 1:iterations
	simulate(cells, cells.size_x, cells.size_y)

	plot_matrix = animal_matrix_to_plot(cells, animal)
	ht = get_heatmap_plot(plot_matrix, animal)

	println("Plotting ", animal)
	display(ht)
	readline()
end
