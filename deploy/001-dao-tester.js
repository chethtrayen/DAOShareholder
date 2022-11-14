module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();


  await deploy('DAOTester', {
    from: deployer,
    log: true,
    args: [1000, 100]
  })
}

module.exports.tags = ['all'];