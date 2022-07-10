using Nash
using Random
using Distributions
using LinearAlgebra
using Nash

DISTANCE = .5 
MAX_LOOPS = 14000
SAMPLES = 5000


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

game = generate_game(
        [-10 -10; 0 -20],
        [-20 0; -1 -1]
       );

s_og = [[.5, .5], [.7, .3]];
s = s_og
old_best = best_reply(game, s, 1)
new_best = old_best
c = 0;
sumt = 0;
for i in 1:SAMPLES
    global sumt, s, c, new_best, old_best;
    s = s_og;
    old_best = best_reply(game, s, 1)
    new_best = old_best
    c = 0;
    while new_best == old_best && c < MAX_LOOPS
        global s, c, new_best, old_best;
        s[2] = perturb(game, s[2], random_distance_vector(DISTANCE, 2))
        new_best = best_reply(game, s, 1)
        c += 1
    end
    sumt += c;
end

println("Diverged after an average of " * string(sumt / SAMPLES) * " perturbations");
