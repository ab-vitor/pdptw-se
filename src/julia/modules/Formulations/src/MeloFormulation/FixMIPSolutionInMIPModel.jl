
function fixMIPSolutionInMIPModel(mipSol::MIPSolution, mipModel::MIPModel, inst::InstanceData)
	for (i, j) in inst.A
		for k in inst.K
			fix(mipModel.x[i, j, k], mipSol.x[i, j, k], force = true)
		end
	end

	for (i, j) in inst.A_m
		for h in inst.H_e[i][j]
			fix(mipModel.phi[i, j, h], mipSol.phi[i, j, h])
		end
	end

	for (i, j) in inst.A_m
		for (iprime, jprime) in inst.A_m
			for h in intersect(inst.H_e[i][j], inst.H_e[iprime][jprime])
				if (i, j) != (iprime, jprime)
					fix(mipModel.gamma[i, j, iprime, jprime, h], mipSol.gamma[i, j, iprime, jprime, h])
				end
			end
		end
	end

	return mipModel

end # function fixMIPSolutionInMIPModel()
