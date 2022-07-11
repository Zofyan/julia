using Nash
using Random
using Distributions
using LinearAlgebra
using Nash

DISTANCE = 0.1
MAX_LOOPS = 1000

function perturb(s, vec)
    new_s = s .- (vec .* s);
    sum2 = sum(new_s);
    new_s = new_s * (1 / sum2);
    return new_s;
end

function random_distance_vector(d, n)
    vec = rand!(zeros(n));
    vec = vec/norm(vec);
    vec = vec * d;
end

### Game of Chicken, Swerve VS Stay
game = generate_game(
        [0 0; 1 -1],
        [-1 1; -20 -20]
        );

for distance in 0:0.1:1
    # Having a perfect 1 or 0 chance results in a Inaccuracy error
    s = [[.99, .01], [0.01, .99]] # Player1 Swerves and Player2 Stays
    # low distances "never" diverge while larger distances diverge quite quickly as there are 2 NE's

    oldstd = stdout
    redirect_stdout(open("/dev/null", "w"))

    previous_ne = last(iterate_best_reply(game, s));
    new_ne = previous_ne;
    c = 0
    while(new_ne == previous_ne && c < MAX_LOOPS)
        #global c, new_ne; # global as Julia sees loops the same as functions and will create separate, local variables.
        s[1] = perturb(s[1], random_distance_vector(distance, 2));# disturb both players by a random vector
        s[2] = perturb(s[2], random_distance_vector(distance, 2));
        new_ne = last(iterate_best_reply(game, s));
        
        c += 1;
    end

    redirect_stdout(oldstd) # recover original stdout

    if(c == MAX_LOOPS)
        println("Does not diverge(within specified limit) for distance " * string(distance))
    else
        println("Diverged after " * string(c) * " cycles for distance " * string(distance))
    end
end
