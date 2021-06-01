package dk.sdu.mmmi.validation

import dk.sdu.mmmi.typescriptdsl.Contains
import dk.sdu.mmmi.typescriptdsl.Equal
import dk.sdu.mmmi.typescriptdsl.NotEqual
import dk.sdu.mmmi.typescriptdsl.Operator

class Helpers {
	static def validateInt(Operator operator) {
		!(operator instanceof Contains)
	}

	static def validateString(Operator operator) {
		operator instanceof Contains || operator instanceof Equal || operator instanceof NotEqual
	}
	
	static def validateBoolean(Operator operator) {
		operator instanceof Equal
	}
}