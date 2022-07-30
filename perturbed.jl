using Nash
using Random
using Distributions
using LinearAlgebra
using BenchmarkTools
using Plots

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 3

MAX_LOOPS = 2000
MAX_STRATEGIES = 10
MAX_PLAYERS = 10
DISTANCE = .00001

function perturb(s, vec)
    new_s = s .- (vec .* s);
    sum2 = sum(new_s);
    new_s = new_s * (1 / sum2);
    return new_s;
end

function random_distance_vector(d, n)
    vec = rand!(zeros(n)) * 2 - ones(n);
    vec = vec/norm(vec);
    vec = vec * d;
    return vec;
end

function random_s(n)
    s = ones(n) / 2;
    return perturb(s, random_distance_vector(1, n));
end

function get_nash(distance, game, s)
    oldstd = stdout
    redirect_stdout(open("/dev/null", "w"))

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
    return c;
end

results = Dict()

for n in 2:2:MAX_STRATEGIES
    println("Strat: " * string(n));
    global game, s, results;
    results[n] = Dict();
    for i in 2:1:MAX_PLAYERS
        println("   Player: " * string(i));
        game = random_nplayers_game(Binomial(20,0.5), repeat([n], i))

        s = repeat([random_s(n)], i)
        c = get_nash(DISTANCE, game, s)
        x = @benchmark get_nash(DISTANCE, game, s)

        oldstd = stdout
        redirect_stdout(open("/dev/null", "w"))
        y = @benchmark iterate_best_reply(game, s)
        redirect_stdout(oldstd)

        results[n][i] = [minimum(x).time, minimum(y).time, c]
    end
end

results = sort(results)
plot();
for (k, res) in results
    plt = plot(title="Number of Strategies: " * string(k), reuse=false);

    res = sort(res);
    sizes = collect(keys(res))
    time_diverge = collect(collect(getindex.(values(res), 1)) * 10^-6)
    time_calc = collect(collect(getindex.(values(res), 2)) * 10^-6)
    counts = collect(collect(getindex.(values(res), 3)))

    plot!(plt,
    sizes,
    [time_diverge time_calc counts],
     ylim=(0, 2000),
     xlim=(2, MAX_PLAYERS),
     labels=["Time to check divergence" "Time to calculate NE" "Rounds to diverge"])
     display(plt)
end
