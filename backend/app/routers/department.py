from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.department import Department
from app.models.user import User
from app.schemas.department import DepartmentCreate, DepartmentOut, DepartmentUpdate, BatchRulesBody
from app.core import require_admin

router = APIRouter(prefix="/departments", tags=["departments"])


@router.get("/", response_model=list[DepartmentOut])
def list_departments(db: Session = Depends(get_db), _=Depends(require_admin)):
    return db.query(Department).order_by(Department.id).all()


@router.post("/", response_model=DepartmentOut, status_code=201)
def create_department(body: DepartmentCreate, db: Session = Depends(get_db), _=Depends(require_admin)):
    if db.query(Department).filter(Department.name == body.name).first():
        raise HTTPException(status_code=400, detail="部门名称已存在")
    dept = Department(name=body.name, description=body.description)
    db.add(dept)
    db.commit()
    db.refresh(dept)
    return dept


@router.patch("/{dept_id}", response_model=DepartmentOut)
def update_department(dept_id: int, body: DepartmentUpdate, db: Session = Depends(get_db), _=Depends(require_admin)):
    dept = db.query(Department).filter(Department.id == dept_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="部门不存在")
    if body.name is not None:
        existing = db.query(Department).filter(Department.name == body.name, Department.id != dept_id).first()
        if existing:
            raise HTTPException(status_code=400, detail="部门名称已存在")
        dept.name = body.name
    if body.description is not None:
        dept.description = body.description
    db.commit()
    db.refresh(dept)
    return dept


@router.delete("/{dept_id}")
def delete_department(dept_id: int, db: Session = Depends(get_db), _=Depends(require_admin)):
    dept = db.query(Department).filter(Department.id == dept_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="部门不存在")
    user_count = db.query(User).filter(User.department_id == dept_id).count()
    if user_count > 0:
        raise HTTPException(status_code=400, detail=f"该部门下还有 {user_count} 名用户，无法删除")
    db.delete(dept)
    db.commit()
    return {"detail": "部门已删除"}


@router.post("/{dept_id}/batch-rules")
def batch_update_rules(dept_id: int, body: BatchRulesBody, db: Session = Depends(get_db), _=Depends(require_admin)):
    dept = db.query(Department).filter(Department.id == dept_id).first()
    if not dept:
        raise HTTPException(status_code=404, detail="部门不存在")

    users = db.query(User).filter(User.department_id == dept_id).all()
    if not users:
        raise HTTPException(status_code=400, detail="该部门下没有用户")

    update_data = body.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="未提供任何更新字段")

    for user in users:
        for field, value in update_data.items():
            setattr(user, field, value)

    db.commit()
    return {"detail": f"已更新 {len(users)} 名用户的打卡规则"}
