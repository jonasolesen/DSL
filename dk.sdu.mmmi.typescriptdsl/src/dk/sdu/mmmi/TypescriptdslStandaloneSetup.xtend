/*
 * generated by Xtext 2.25.0
 */
package dk.sdu.mmmi


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class TypescriptdslStandaloneSetup extends TypescriptdslStandaloneSetupGenerated {

	def static void doSetup() {
		new TypescriptdslStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
