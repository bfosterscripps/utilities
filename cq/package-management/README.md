# Package Management

## How to Create a Package

You need a few things for this.
First - you will need filter paths, locations to the nodes you would like to package up.

Put these in a file named `cq-package-filters.dat`.

You will also need to know the name of your new package, and where you wish to install it.

Here is a template for a comand:

`bash cq-package-manager.sh C <the name of your new package> <environment on which to make it>`

e.g.

`bash cq-package-manager.sh C HTA-1234 dev`

It will create the package on the environment you specified, add the filters, build it, and then download the zip into a local directory named `packages`.


## How to Install a Package


