function generate_game(n)
    game = Vector{Vector}()
    for i in range(0, 1, n)
        push!(game, Vector{Tuple}())
        for i in range(0, 1, n)
            push!(last(game), (round(rand() * 20 - 10), round(rand() * 20 - 10)))
        end
    end

    return game
end


function pretty_print(game)
    for g in game
        for t in g
            print(t)
            print("       ")
        end
        print("\n")
    end
end

pretty_print(generate_game(3));