// Licensed to the Apache Software Foundation (ASF) under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  The ASF licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

package org.apache.doris.nereids.trees.plans.logical;

import org.apache.doris.catalog.View;
import org.apache.doris.nereids.memo.GroupExpression;
import org.apache.doris.nereids.properties.FdItem;
import org.apache.doris.nereids.properties.FunctionalDependencies;
import org.apache.doris.nereids.properties.LogicalProperties;
import org.apache.doris.nereids.trees.expressions.Expression;
import org.apache.doris.nereids.trees.expressions.Slot;
import org.apache.doris.nereids.trees.plans.Plan;
import org.apache.doris.nereids.trees.plans.PlanType;
import org.apache.doris.nereids.trees.plans.visitor.PlanVisitor;
import org.apache.doris.nereids.util.Utils;

import com.google.common.base.Preconditions;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableSet;

import java.util.List;
import java.util.Objects;
import java.util.Optional;
import java.util.function.Supplier;

/** LogicalView */
public class LogicalView<BODY extends Plan> extends LogicalUnary<BODY> {
    private final View view;

    /** LogicalView */
    public LogicalView(View view, BODY body) {
        super(PlanType.LOGICAL_VIEW, Optional.empty(), Optional.empty(), body);
        this.view = Objects.requireNonNull(view, "catalog can not be null");
        Preconditions.checkArgument(body instanceof LogicalPlan);
    }

    @Override
    public <R, C> R accept(PlanVisitor<R, C> visitor, C context) {
        return visitor.visitLogicalView(this, context);
    }

    @Override
    public List<? extends Expression> getExpressions() {
        return ImmutableList.of();
    }

    public String getCatalog() {
        return view.getDatabase().getCatalog().getName();
    }

    public String getDb() {
        return view.getDatabase().getFullName();
    }

    public String getName() {
        return view.getName();
    }

    public String getViewString() {
        return view.getInlineViewDef();
    }

    public View getView() {
        return view;
    }

    @Override
    public LogicalProperties getLogicalProperties() {
        return child().getLogicalProperties();
    }

    @Override
    public Plan withGroupExpression(Optional<GroupExpression> groupExpression) {
        return new LogicalView(view, child());
    }

    @Override
    public Plan withGroupExprLogicalPropChildren(Optional<GroupExpression> groupExpression,
            Optional<LogicalProperties> logicalProperties, List<Plan> children) {
        return new LogicalView(view, child());
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) {
            return true;
        }
        if (o == null || getClass() != o.getClass()) {
            return false;
        }
        LogicalView that = (LogicalView) o;
        return Objects.equals(view, that.view);
    }

    @Override
    public String toString() {
        return Utils.toSqlString("LogicalView",
                "catalog", getCatalog(),
                "db", getDb(),
                "name", getName()
        );
    }

    @Override
    public int hashCode() {
        return Objects.hash(getCatalog(), getDb(), getName());
    }

    @Override
    public List<Slot> computeOutput() {
        return child().getOutput();
    }

    @Override
    public FunctionalDependencies computeFuncDeps(Supplier<List<Slot>> outputSupplier) {
        return ((LogicalPlan) child()).computeFuncDeps(outputSupplier);
    }

    @Override
    public ImmutableSet<FdItem> computeFdItems(Supplier<List<Slot>> outputSupplier) {
        return ((LogicalPlan) child()).computeFdItems(outputSupplier);
    }

    @Override
    public Plan withChildren(List<Plan> children) {
        return new LogicalView<>(view, (LogicalPlan) children.get(0));
    }
}
