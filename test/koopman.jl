using OrdinaryDiffEq, Distributions,
      DiffEqUncertainty, Test, DiffEqGPU

function f(du,u,p,t)
  @inbounds begin
    du[1] = dx = p[1]*u[1] - u[1]*u[2]
    du[2] = dy = -3*u[2] + u[1]*u[2]
  end
  nothing
end

u0 = [1.0;1.0]
tspan = (0.0,10.0)
p = [1.5]
prob = ODEProblem(f,u0,tspan,p)
sol = solve(remake(prob,u0=u0),Tsit5())
cost(sol) = sum(max(x[1]-6,0) for x in sol.u)
u0s = [Uniform(0.25,5.5),Uniform(0.25,5.5)]
ps  = [Uniform(0.5,2.0)]
@time sol = koopman_cost(u0s,ps,cost,prob,Tsit5();iabstol=1e-3,ireltol=1e-3,maxiters=1000,saveat=0.1)
c1, e1 = sol.u, sol.resid
@time c2 = montecarlo_cost(u0s,ps,cost,prob,Tsit5(),EnsembleThreads();trajectories=100000,saveat=0.1)
@test abs(c1 - c2) < 0.1

#=
using DiffEqGPU
@time c2 = montecarlo_cost(u0s,ps,cost,prob,Tsit5(),EnsembleGPUArray();trajectories=100000,saveat=0.1)
=#
