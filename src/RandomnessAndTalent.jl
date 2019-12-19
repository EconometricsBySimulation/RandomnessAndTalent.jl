cd(raw"C:\Users\francis.smart.ctr\RandomnessAndTalent.jl")
Pkg.activate(".")


module RandomnessAndTalent

using DataFrames, Gadfly

xgrid = 200
ygrid = 200

ni = 1000
ix = rand(1:xgrid, ni)
iy = rand(1:ygrid, ni)

talentave = .6
talentsd  = .1

italent = max.(0, min.(1, talentave .+ talentsd.*rand(Normal(), ni)))

maxt = round(maximum(italent), digits=2)
mint = round(minimum(italent), digits=2)

print("Maximum Talent:$maxt \nMinimum Talent:$mint")

ngood = 250

goodx = rand(1:xgrid, ngood)
goody = rand(1:ygrid, ngood)

nbad  = 250
badx = rand(1:xgrid, ngood)
bady = rand(1:ygrid, ngood)

timeperiods    = 80
initialcapital = 100.0

people = DataFrame(x = ix,    y = iy,    type = "individual")
good   = DataFrame(x = goodx, y = goody, type = "good")
bad    = DataFrame(x = badx,  y = bady,  type = "bad")

gridset = vcat(people, good, bad)

set_default_plot_size(20cm, 16cm)  # hide

plot(gridset, x = "x", y = "y", color = "type", Geom.point, Theme(point_size = 2pt),
     Scale.x_continuous(minvalue=0, maxvalue=xgrid),
     Scale.y_continuous(minvalue=0, maxvalue=ygrid))

function randomwalk!(dataframe, rstep=1, xborder = xgrid, yborder = ygrid)
  roundboundary(xmax, x) = round.(max.(0, min.(x, xmax)))

  dataframe.x =  roundboundary(xborder, dataframe.x + rstep.*rand(Normal(), size(dataframe, 1)))
  dataframe.y =  roundboundary(yborder, dataframe.y + rstep.*rand(Normal(), size(dataframe, 1)))

end

function nextphase(dataframe, good = dataframe(x=-1, y=-1), bad = dataframe(x=-1, y=-1), verbose = false)
  t = maximum(dataframe.t)
  recentdata = dataframe[dataframe.t .== t, :]
  recentdata.t .+= 1
  recentdata.good .= 0
  recentdata.realised .= 0
  recentdata.bad .= 0

  #Loop through each individual and check if a good event happened
  for i in 1:size(recentdata, 1)
    # Check if good event could happen
    if sum((good.x .== recentdata.x[i]) .& (good.y .== recentdata.y[i])) > 0
        verbose && println("$i possibly get fortuitous event")
        recentdata.good[i] = 1
        if rand(1,1)[1] < recentdata.talent[i]
            recentdata.capital[i] *= 2
            recentdata.realised[i] = 1
            verbose && println("$i get fortuitous event")

        end
    end

    # Check if bad even happens
    if sum((bad.x .== recentdata.x[i]) .& (bad.y .== recentdata.y[i])) > 0
        verbose && println("$i is unlucky")
        recentdata.capital[i] *= .5
        recentdata.bad[i] = 1
    end
  end

  dataframe = vcat(dataframe, recentdata)
end # module

peopleset = DataFrame(i = 1:ni, t = 0, capital = initialcapital, talent = italent,
  x = ix, y = iy, good=0, realised=0, bad=0)

for i in 1:timeperiods;
    global peopleset
    peopleset = nextphase(peopleset, good, bad);
    randomwalk!(good)
    randomwalk!(bad)
end

retirement = peopleset[peopleset.t .== timeperiods,:]

top = retirement[retirement.capital .> 1000, :].i

plot(peopleset[[i in top for i in peopleset.i],:], x = "t", y = "capital", color = "i",
  Geom.point, Geom.line, Scale.y_log)

plot(peopleset[[i in top for i in peopleset.i],:], x = "t", y = "capital", color = "i",
  Geom.point, Geom.line)

peopleset[[i in top for i in peopleset.i] .& (peopleset.t .== 0), :talent]

plot(peopleset[peopleset.t .== 80,:], x = "talent", y = "capital", Geom.point, Scale.y_log)

eventcounts = by(peopleset, :i,
  (:good, :bad, :realised) => x -> (good = sum(x[1]), bad = sum(x[2]), realised = sum(x[3])))

peopleset[peopleset.good .== 1, :]

mean(eventcounts.good)
mean(eventcounts.bad)
mean(eventcounts.realised)

end #module
