using Nash
using Random
using Distributions
using LinearAlgebra
using BenchmarkTools
using PlotlyJS
using DataFrames
using Statistics

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 12

MAX_LOOPS = 2000
SAMPLES = 2500
DISTANCE = .4

function perturb(s, vec)
    new_s = s .- (vec .* s);
    sum2 = sum(new_s);
    new_s = new_s * (1 / sum2);
    return new_s;
end

function random_s(n)
    s = ones(n) / 2;
    return perturb(s, random_distance_vector(1, n));
end

function random_distance_vector(d, n)
    vec = rand!(zeros(n)) * 2 - ones(n);
    vec = vec/norm(vec);
    vec = vec * d;
    return vec;
end

function get_nash(distance, game)
    oldstd = stdout
    redirect_stdout(open("NUL", "w"))
    s = repeat([random_s(2)], 2)

    previous_ne = last(iterate_best_reply(game, s));
    new_ne = previous_ne;
    c = 0
    while(new_ne == previous_ne && c < MAX_LOOPS)
        for i in 1:1:length(s)
            s[i] = perturb(s[i], random_distance_vector(distance, length(s[i])));# disturb both players by a random vector
        end
        new_ne = last(iterate_best_reply(game, s));

        c += 1;
    end

    redirect_stdout(oldstd) # recover original stdout
    return (c, s);
end


chicken = generate_game(
    [0 0; 3 -1],
    [-1 3; -20 -20]
)
prisoners = generate_game(
    [1 1; 6 0],
    [0 6; 4 4]
)
battle_sexes = generate_game(
    [4 1; 0 0],
    [0 0; 1 4]
)

games = Dict()
games["Game of Chicken"] = chicken
games["Prisoners Dilemma"] = prisoners
games["Battle of the Sexes"] = battle_sexes

results = Dict()
for (k, n) in games
    global game, s, results;
    game = n

    c_total = 0
    cs = []
    for i in 1:1:SAMPLES
        c, s = get_nash(DISTANCE, game)
        append!(cs, c)
    end

    x = @benchmark get_nash(DISTANCE, game)

    oldstd = stdout
    redirect_stdout(open("NUL", "w"))
    y = @benchmark iterate_best_reply(game, s)
    redirect_stdout(oldstd)

    results[k] = [minimum(x).time, minimum(y).time, mean(cs), median(cs)]
end

df = DataFrame(
    games=collect(keys(results)),
    time_diverge=getindex.(values(results), 1) * 10^-6,
    time_ne=getindex.(values(results), 2) * 10^-6,
    count_mean=getindex.(values(results), 3),
    count_median=getindex.(values(results), 4)
    )


plot(

    [bar(df, x=:games, y=y, name=String(y)) for y in [:time_diverge, :time_ne, :count_mean, :count_median]],

    Layout(title="Few Games NE Divergence"),


)
