


CREATE OR REPLACE FUNCTION process_payroll(varchar(12), varchar(12), varchar(12), varchar(12)) RETURNS varchar(120) AS $$
DECLARE
	rec 		RECORD;
	msg 		varchar(120);
BEGIN
	IF ($3 = '1') THEN
		UPDATE employee_adjustments SET amount = 0
		FROM employee_month 
		WHERE (adjustment_id IN (15, 16, 17))
			AND (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
			
		UPDATE employee_adjustments SET tax_reduction_amount = 0 
		FROM employee_month 
		WHERE (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int));
			
		UPDATE employee_adjustments SET amount = 0 
		FROM employee_month 
		WHERE (employee_adjustments.employee_month_id = employee_month.employee_month_id) 
			AND (employee_month.period_id = CAST($1 as int))
			AND (adjustment_id IN (SELECT adjustment_id FROM adjustments WHERE formural is not null));

		UPDATE employee_adjustments 
			SET amount = ((vw_employee_month.basic_pay + vw_employee_month.full_allowance) * 0.15) - get_house_rent(vw_employee_month.employee_month_id)
		FROM vw_employee_month 
		WHERE (adjustment_id = 17)
			AND (employee_adjustments.employee_month_id = vw_employee_month.employee_month_id) 
			AND (vw_employee_month.period_id = CAST($1 as int));
	
		PERFORM updTax(employee_month_id, period_id)
		FROM employee_month
		WHERE (period_id = CAST($1 as int));
		
		msg := 'Payroll Processed';
	ELSIF ($3 = '2') THEN
		UPDATE periods SET entity_id = CAST($2 as int), approve_status = 'Completed'
		WHERE (period_id = CAST($1 as int));

		msg := 'Application for approval';
	ELSIF ($3 = '3') THEN
		UPDATE periods SET closed = true
		WHERE (period_id = CAST($1 as int));

		msg := 'Period closed';
	ELSIF ($3 = '4') THEN
		UPDATE periods SET closed = false
		WHERE (period_id = CAST($1 as int));

		msg := 'Period opened';
	END IF;

	RETURN msg;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION updtax(int, int) RETURNS float AS $$
DECLARE
	reca 					RECORD;
	income 					REAL;
	tax 					REAL;
	InsuranceRelief 		REAL;
	v_income				real;
BEGIN

	FOR reca IN SELECT employee_tax_types.employee_tax_type_id, employee_tax_types.tax_type_id, period_tax_types.formural,
			 period_tax_types.employer, period_tax_types.employer_ps
		FROM employee_tax_types INNER JOIN period_tax_types ON (employee_tax_types.tax_type_id = period_tax_types.tax_type_id)
		WHERE (employee_month_id = $1) AND (Period_Tax_Types.Period_ID = $2)
		ORDER BY Period_Tax_Types.Tax_Type_order LOOP

		EXECUTE 'SELECT ' || reca.formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;
		
		IF(reca.tax_type_id = 1)THEN 	---- PAYE
			UPDATE employee_adjustments SET amount = tax * .7
			WHERE (employee_month_id = $1) AND (adjustment_id = 15);
		END IF;
		
		IF(reca.tax_type_id = 3)THEN 	---- NHIF
			UPDATE employee_adjustments SET amount = tax * .75
			WHERE (employee_month_id = $1) AND (adjustment_id = 16);
		END IF;
		
		EXECUTE 'SELECT ' || reca.formural || ' FROM employee_tax_types WHERE employee_tax_type_id = ' || reca.employee_tax_type_id 
		INTO tax;

		UPDATE employee_tax_types SET amount = tax, employer = reca.employer + (tax * reca.employer_ps / 100)
		WHERE employee_tax_type_id = reca.employee_tax_type_id;
	END LOOP;

	RETURN tax;
END;
$$ LANGUAGE plpgsql;


