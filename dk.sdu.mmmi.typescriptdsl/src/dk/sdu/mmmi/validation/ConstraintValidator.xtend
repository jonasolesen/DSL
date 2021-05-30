package dk.sdu.mmmi.validation

import dk.sdu.mmmi.typescriptdsl.Add
import dk.sdu.mmmi.typescriptdsl.And
import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.BoolType
import dk.sdu.mmmi.typescriptdsl.BooleanConstraint
import dk.sdu.mmmi.typescriptdsl.Comparison
import dk.sdu.mmmi.typescriptdsl.Constraint
import dk.sdu.mmmi.typescriptdsl.Div
import dk.sdu.mmmi.typescriptdsl.Expression
import dk.sdu.mmmi.typescriptdsl.Field
import dk.sdu.mmmi.typescriptdsl.IntType
import dk.sdu.mmmi.typescriptdsl.Mul
import dk.sdu.mmmi.typescriptdsl.Or
import dk.sdu.mmmi.typescriptdsl.Parenthesis
import dk.sdu.mmmi.typescriptdsl.Sub
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage
import java.util.List
import org.eclipse.xtext.validation.Check

import static dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage.Literals.*
import static org.eclipse.xtext.EcoreUtil2.*

class ConstraintValidator extends AbstractTypescriptdslValidator {

	@Check
	def validateField(Field field) {
		if (!(field.attribute.type instanceof IntType))
			error('''Attribute «field.attribute.name» is not of type int''',
				TypescriptdslPackage.Literals.FIELD__ATTRIBUTE)
	}

	@Check
	def validateBoolean(BooleanConstraint constraint) {
		val attribute = getContainerOfType(constraint, Attribute)
		if (!(attribute.type instanceof BoolType)) {
			error('''Is operator can only be used with boolean types''', BOOLEAN_CONSTRAINT__OPERATOR)
		}
	}

	@Check
	def validateConstraint(Attribute attribute) {
		val List<Comparison> comparisons = attribute.constraint.extractListOfCompareConstraints(newArrayList)

		comparisons.forEach [
			val list = countFields
			if (!list.get(0).forall[!list.get(1).contains(it)]) {
				error('Attribute name is the same as on the left side', it,
					TypescriptdslPackage.Literals.COMPARISON__RIGHT)
			}
		]
	}

	@Check
	def validatePrimary(Table table) {
		val primaries = table.attributes.filter[it.primary]
		if (primaries.empty) {
			error('''Table «table.name» does not contain a primary key.''', TypescriptdslPackage.Literals.TABLE__NAME)
		}

		if (primaries.length > 1) {
			error('''Table «table.name» contains more than one primary key.''',
				TypescriptdslPackage.Literals.TABLE__NAME)
		}
	}

	def List<Comparison> extractListOfCompareConstraints(Constraint con, List<Comparison> list) {
		switch con {
			Or: {
				con.left.extractListOfCompareConstraints(list)
				con.right.extractListOfCompareConstraints(list)
			}
			And: {
				con.left.extractListOfCompareConstraints(list)
				con.right.extractListOfCompareConstraints(list)
			}
			Comparison:
				list.add(con)
		}

		list
	}

	def countFields(Comparison con) {
		val List<String> left = newArrayList()
		val List<String> right = newArrayList()
		con.left.extractFields(left)
		con.right.extractFields(right)
		return #[left, right]
	}

	def void extractFields(Expression exp, List<String> list) {
		switch exp {
			Add: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Sub: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Mul: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Div: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Parenthesis:
				exp.exp.extractFields(list)
			Field:
				list.add(exp.attribute.name)
		}
	}
}
