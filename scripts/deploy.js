async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

  const KriptoOG = await hre.ethers.getContractFactory("KriptoOG");
  const kriptoOG = await Turtles.deploy(
    "0x58807baD0B376efc12F5AD86aAc70E78ed67deaE"
  );

    console.log("Token address:", turtles.address);
  }

  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
